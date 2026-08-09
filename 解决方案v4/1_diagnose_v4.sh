#!/system/bin/sh
# ============================================
# AutoKit 深度诊断 v4
# 全面检查车机状态，输出到屏幕和日志文件
# 执行方式：RE管理器 → Root权限执行
# ============================================

LOG="/sdcard/autokit_diag.log"
echo "" > "$LOG"

log() {
    echo "$1"
    echo "$1" >> "$LOG"
}

log "============================================"
log " AutoKit 深度诊断 v4"
log " $(date)"
log "============================================"

PKG="cn.manstep.phonemirrorBox"

# ---- 1. 系统基本信息 ----
log ""
log "[1] 系统信息"
log "  Android: $(getprop ro.build.version.release)"
log "  SDK: $(getprop ro.build.version.sdk)"
log "  Build: $(getprop ro.build.id)"
log "  Product: $(getprop ro.build.product)"
log "  SELinux: $(getenforce 2>/dev/null || echo unknown)"
log "  Quick Boot: $(getprop ro.quickboot.enable)"
log "  Boot type: $(getprop ro.boot.mode)"
log "  Uptime: $(cat /proc/uptime 2>/dev/null | awk '{print $1}')s"

# ---- 2. ADB 状态 ----
log ""
log "[2] ADB 状态"
log "  persist.sys.usb.config: $(getprop persist.sys.usb.config)"
log "  sys.usb.config: $(getprop sys.usb.config)"
log "  sys.usb.state: $(getprop sys.usb.state)"
log "  service.adb.tcp.port: $(getprop service.adb.tcp.port)"
log "  adbd running: $(ps | grep adbd | grep -v grep | head -1)"
log "  ADB listen ports:"
netstat -tlnp 2>/dev/null | grep 5555 >> "$LOG"
log "  $(netstat -tlnp 2>/dev/null | grep 5555)"

# ---- 3. 网络信息 ----
log ""
log "[3] 网络接口"
log "  WiFi IP: $(ifconfig wlan0 2>/dev/null | grep 'inet addr' || netcfg 2>/dev/null | grep wlan0)"
log "  Eth IP: $(ifconfig eth0 2>/dev/null | grep 'inet addr' || netcfg 2>/dev/null | grep eth0)"

# ---- 4. 存储空间 ----
log ""
log "[4] 存储空间"
df 2>/dev/null >> "$LOG"
df 2>/dev/null | head -5
log "  /data free: $(df /data 2>/dev/null | tail -1)"
log "  /system free: $(df /system 2>/dev/null | tail -1)"

# ---- 5. AutoKit 安装状态 ----
log ""
log "[5] AutoKit 安装状态"

# 包管理器中的状态
PM_INFO=$(pm list packages -f 2>/dev/null | grep phonemirror)
log "  pm list: $PM_INFO"

PM_SYSTEM=$(pm list packages -s 2>/dev/null | grep phonemirror)
if [ -n "$PM_SYSTEM" ]; then
    log "  ✓ 是系统应用"
else
    log "  ✗ 不是系统应用（或未安装）"
fi

PM_ALL=$(pm list packages 2>/dev/null | grep phonemirror)
if [ -n "$PM_ALL" ]; then
    log "  ✓ 已安装"
else
    log "  ✗ 未安装"
fi

# dumpsys信息
log "  --- dumpsys package info ---"
dumpsys package $PKG 2>/dev/null | grep -E "versionCode|versionName|codePath|dataDir|firstInstall|lastUpdate|flags" >> "$LOG"
dumpsys package $PKG 2>/dev/null | grep -E "versionCode|codePath|dataDir|flags" | while read line; do
    log "  $line"
done

# ---- 6. 文件系统检查 ----
log ""
log "[6] 文件系统检查"

# /system/priv-app
if [ -f /system/priv-app/AutoKit.apk ]; then
    log "  ✓ /system/priv-app/AutoKit.apk 存在"
    ls -la /system/priv-app/AutoKit.apk >> "$LOG"
else
    log "  ✗ /system/priv-app/AutoKit.apk 不存在"
fi

# /system/app
ls /system/app/*utokit* /system/app/*phonemirror* /system/app/*AutoKit* 2>/dev/null >> "$LOG"
ls /system/priv-app/ 2>/dev/null >> "$LOG"

# /data/app
log "  --- /data/app 中 AutoKit ---"
ls -la /data/app/$PKG* /data/app/*phonemirror* 2>/dev/null >> "$LOG"
ls -la /data/app/$PKG* /data/app/*phonemirror* 2>/dev/null | while read line; do
    log "  $line"
done
if [ $? -ne 0 ]; then
    # Android 4.4 format
    ls -la /data/app/ 2>/dev/null | grep -i "phonemirror\|autokit" >> "$LOG"
    ls -la /data/app/ 2>/dev/null | grep -i "phonemirror\|autokit" | while read line; do
        log "  $line"
    done
fi

# ---- 7. Dalvik 缓存 ----
log ""
log "[7] Dalvik 缓存"
ls -la /data/dalvik-cache/*phonemirror* /data/dalvik-cache/*AutoKit* 2>/dev/null >> "$LOG"
ls -la /data/dalvik-cache/*phonemirror* /data/dalvik-cache/*AutoKit* 2>/dev/null | while read line; do
    log "  $line"
done
DCACHE_COUNT=$(ls /data/dalvik-cache/*phonemirror* /data/dalvik-cache/*AutoKit* 2>/dev/null | wc -l)
log "  dalvik-cache 条目数: $DCACHE_COUNT"

# ---- 8. 白名单 / 黑名单 ----
log ""
log "[8] 白名单 / 黑名单"
if [ -f /system/usr/bootwhitelist.txt ]; then
    log "  --- bootwhitelist.txt ---"
    cat /system/usr/bootwhitelist.txt | while read line; do
        log "    $line"
    done
    if grep -q "$PKG" /system/usr/bootwhitelist.txt; then
        log "  ✓ AutoKit 在白名单中"
    else
        log "  ✗ AutoKit 不在白名单中"
    fi
else
    log "  ✗ bootwhitelist.txt 不存在"
fi

if [ -f /system/usr/bootblacklist.txt ]; then
    log "  --- bootblacklist.txt ---"
    cat /system/usr/bootblacklist.txt | while read line; do
        log "    $line"
    done
    if grep -q "$PKG" /system/usr/bootblacklist.txt; then
        log "  ✗ 警告: AutoKit 在黑名单中!"
    else
        log "  ✓ AutoKit 不在黑名单中"
    fi
fi

# ---- 9. 启动脚本检查 ----
log ""
log "[9] 启动脚本"
if [ -f /system/etc/install-recovery.sh ]; then
    log "  ✓ install-recovery.sh 存在"
    log "  --- 内容 ---"
    cat /system/etc/install-recovery.sh >> "$LOG"
    cat /system/etc/install-recovery.sh | head -20 | while read line; do
        log "    $line"
    done
else
    log "  ✗ install-recovery.sh 不存在"
fi

if [ -f /system/etc/install-recovery.sh.original ]; then
    log "  ✓ install-recovery.sh.original 备份存在"
fi

# ---- 10. 开机日志 ----
log ""
log "[10] AutoKit 相关日志"
if [ -f /data/local/tmp/autokit.log ]; then
    log "  --- autokit.log (最后20行) ---"
    tail -20 /data/local/tmp/autokit.log >> "$LOG"
    tail -5 /data/local/tmp/autokit.log | while read line; do
        log "  $line"
    done
fi

# ---- 11. init.d 支持 ----
log ""
log "[11] init.d 支持"
if [ -d /system/etc/init.d ]; then
    log "  ✓ /system/etc/init.d 存在"
    ls /system/etc/init.d/ >> "$LOG"
else
    log "  ✗ /system/etc/init.d 不存在"
fi

# ---- 12. 挂载状态 ----
log ""
log "[12] /system 挂载状态"
mount | grep system >> "$LOG"
mount | grep system | while read line; do
    log "  $line"
done

# ---- 13. /system 可写性测试 ----
log ""
log "[13] /system 可写性测试"
mount -o rw,remount /system 2>/dev/null
TESTFILE="/system/.diag_test_$$"
echo "test" > "$TESTFILE" 2>/dev/null
if [ -f "$TESTFILE" ]; then
    log "  ✓ /system 可写"
    rm "$TESTFILE"
else
    log "  ✗ /system 不可写!"
fi
mount -o ro,remount /system 2>/dev/null

# ---- 14. 尝试启动 AutoKit ----
log ""
log "[14] 尝试启动 AutoKit"
am start -n "$PKG/.CheckActivity" 2>&1 | while read line; do
    log "  $line"
done

# ---- 15. logcat 相关错误 ----
log ""
log "[15] 系统日志中 AutoKit 相关错误(最近)"
logcat -d 2>/dev/null | grep -i "phonemirror\|AutoKit\|dexopt" | tail -30 >> "$LOG"

log ""
log "============================================"
log " 诊断完成!"
log " 完整日志已保存到: /sdcard/autokit_diag.log"
log " 请将此文件复制到U盘带给电脑查看"
log "============================================"
