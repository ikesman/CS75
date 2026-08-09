#!/system/bin/sh
# ============================================
# AutoKit 终极修复 v4
#
# 综合v1-v3所有经验，多层保护：
#   Layer 1 - 系统应用安装（/system/priv-app）
#   Layer 2 - 启动白名单保护
#   Layer 3 - 开机自动修复脚本（清缓存+重装+启动）
#   Layer 4 - Dalvik缓存预优化
#
# 前提：
#   - /sdcard/ 下有 AutoKit_2022.11.15.1535.apk
#   - Root权限
#
# 执行方式：RE管理器 → Root权限执行
# ============================================

LOG="/sdcard/autokit_fix_v4.log"
echo "" > "$LOG"

log() {
    echo "$1"
    echo "$(date '+%H:%M:%S') $1" >> "$LOG"
}

PKG="cn.manstep.phonemirrorBox"
ACT="cn.manstep.phonemirrorBox/.CheckActivity"
APK="/sdcard/AutoKit_2022.11.15.1535.apk"
TARGET="/system/priv-app/AutoKit.apk"
WHITELIST="/system/usr/bootwhitelist.txt"
BLACKLIST="/system/usr/bootblacklist.txt"
RECOVERY="/system/etc/install-recovery.sh"
BOOTSCRIPT="/system/bin/autokit_onboot.sh"

log "============================================"
log " AutoKit 终极修复 v4"
log "============================================"

# ---- 检查APK ----
if [ ! -f "$APK" ]; then
    log ""
    log "[!] 错误：缺少 $APK"
    log "    请先将 AutoKit APK 复制到 /sdcard/ 根目录"
    exit 1
fi
log "[OK] APK文件存在: $APK"

# ---- Step 1: 停止旧进程 ----
log ""
log "[1/8] 停止 AutoKit 旧进程..."
am force-stop $PKG 2>/dev/null
sleep 1
# 杀掉所有残留进程
for pid in $(ps 2>/dev/null | grep phonemirror | awk '{print $2}'); do
    kill -9 $pid 2>/dev/null
done
log "  已强停所有 AutoKit 进程"

# ---- Step 2: 卸载用户版 ----
log ""
log "[2/8] 卸载用户版 AutoKit..."
pm uninstall $PKG 2>/dev/null
log "  用户版已卸载（如果存在）"

# ---- Step 3: 挂载 /system 可写 ----
log ""
log "[3/8] 挂载 /system 可写..."
mount -o rw,remount /system 2>/dev/null
if [ $? -ne 0 ]; then
    mount -o rw,remount /system /system 2>/dev/null
    if [ $? -ne 0 ]; then
        mount -o rw,remount /dev/block/mmcblk0p5 /system 2>/dev/null
        if [ $? -ne 0 ]; then
            log "[!] 挂载 /system 失败! 尝试所有方法均失败"
            log "    检查mount状态:"
            mount | grep system >> "$LOG"
            exit 1
        fi
    fi
fi
# 验证可写
echo "test" > /system/.write_test_$$ 2>/dev/null
if [ -f /system/.write_test_$$ ]; then
    rm /system/.write_test_$$
    log "  ✓ /system 已挂载为可写"
else
    log "[!] /system 挂载命令成功但实际不可写!"
    exit 1
fi

# ---- Step 4: 白名单+黑名单处理 ----
log ""
log "[4/8] 处理白名单/黑名单..."

# 备份白名单
if [ -f "$WHITELIST" ] && [ ! -f "${WHITELIST}.bak_v4" ]; then
    cp "$WHITELIST" "${WHITELIST}.bak_v4"
    log "  已备份白名单"
fi

# 添加到白名单
if [ -f "$WHITELIST" ]; then
    if ! grep -q "$PKG" "$WHITELIST" 2>/dev/null; then
        echo "$PKG" >> "$WHITELIST"
        log "  ✓ 已添加到白名单"
    else
        log "  已在白名单中,跳过"
    fi
else
    echo "$PKG" > "$WHITELIST"
    chmod 644 "$WHITELIST"
    log "  ✓ 创建白名单并添加"
fi

# 从黑名单移除
if [ -f "$BLACKLIST" ]; then
    if grep -q "$PKG" "$BLACKLIST" 2>/dev/null; then
        if [ ! -f "${BLACKLIST}.bak_v4" ]; then
            cp "$BLACKLIST" "${BLACKLIST}.bak_v4"
        fi
        grep -v "$PKG" "$BLACKLIST" > "${BLACKLIST}.tmp"
        mv "${BLACKLIST}.tmp" "$BLACKLIST"
        log "  ✓ 已从黑名单移除"
    else
        log "  不在黑名单中,OK"
    fi
fi

log "  当前白名单:"
cat "$WHITELIST" 2>/dev/null | while read line; do
    log "    $line"
done

# ---- Step 5: 安装为系统应用 ----
log ""
log "[5/8] 安装为系统应用..."

# 删除旧的系统APK（如果版本不对）
if [ -f "$TARGET" ]; then
    rm "$TARGET"
    log "  已删除旧版本"
fi

cp "$APK" "$TARGET"
if [ $? -ne 0 ]; then
    log "[!] 复制APK到 $TARGET 失败!"
    log "    /system 空间: $(df /system 2>/dev/null | tail -1)"
    mount -o ro,remount /system 2>/dev/null
    exit 1
fi
chmod 644 "$TARGET"
chown 0:0 "$TARGET"
# 确保和其他priv-app一样的SELinux上下文
chcon u:object_r:system_file:s0 "$TARGET" 2>/dev/null
log "  ✓ APK已安装到 $TARGET"
log "  $(ls -la $TARGET)"

# ---- Step 6: 清理所有缓存 ----
log ""
log "[6/8] 清理 dalvik 缓存和应用数据..."
rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
rm -f /data/dalvik-cache/*phonemirrorBox* 2>/dev/null
rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
rm -rf /data/data/$PKG/cache 2>/dev/null
rm -rf /data/data/$PKG/code_cache 2>/dev/null
# 不删除 /data/data/$PKG 整个目录，保留用户设置
log "  ✓ dalvik缓存和应用缓存已清理"

# ---- Step 7: 创建开机自动修复脚本 ----
log ""
log "[7/8] 安装开机自动修复脚本..."

# 创建自修复脚本（每次开机运行）
cat > "$BOOTSCRIPT" << 'BOOTEOF'
#!/system/bin/sh
# AutoKit 开机自动修复 v4
# 每次开机自动执行: 检查+修复+启动
LOG="/data/local/tmp/autokit_boot.log"
PKG="cn.manstep.phonemirrorBox"
ACT="cn.manstep.phonemirrorBox/.CheckActivity"
APK_SYS="/system/priv-app/AutoKit.apk"
APK_SD="/sdcard/AutoKit_2022.11.15.1535.apk"

log() { echo "$(date '+%m-%d %H:%M:%S') $1" >> "$LOG" 2>/dev/null; }
log "===== boot script started ====="

# 等待系统就绪
N=0
while [ $N -lt 90 ]; do
    pm path $PKG >/dev/null 2>&1 && break
    # 如果pm还没准备好,也等
    pm list packages >/dev/null 2>&1 && break
    sleep 1
    N=$((N+1))
done
log "system ready after ${N}s"

# 检查AutoKit是否已安装
INSTALLED=$(pm path $PKG 2>/dev/null)
log "installed: $INSTALLED"

if [ -z "$INSTALLED" ]; then
    log "AutoKit not installed, attempting repair..."
    
    # 尝试直接安装系统APK
    if [ -f "$APK_SYS" ]; then
        # 清理损坏的dalvik缓存
        rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
        rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
        
        # 重新扫描包(触发系统重新识别priv-app)
        pm install -r "$APK_SYS" 2>/dev/null
        log "reinstall from system: $?"
    fi
    
    # 如果还没安装,尝试SD卡上的APK
    INSTALLED=$(pm path $PKG 2>/dev/null)
    if [ -z "$INSTALLED" ] && [ -f "$APK_SD" ]; then
        # 等sdcard
        M=0
        while [ $M -lt 30 ] && [ ! -f "$APK_SD" ]; do
            sleep 1
            M=$((M+1))
        done
        pm install -r -d "$APK_SD" 2>/dev/null
        log "reinstall from sdcard: $?"
    fi
fi

# 再次确认
sleep 2
INSTALLED=$(pm path $PKG 2>/dev/null)
if [ -n "$INSTALLED" ]; then
    log "AutoKit ready: $INSTALLED"
    
    # 尝试启动
    am start -n "$ACT" 2>/dev/null
    log "app launched"
else
    log "FAILED: AutoKit could not be installed!"
fi

log "===== boot script done ====="
BOOTEOF

chmod 755 "$BOOTSCRIPT"
chown 0:0 "$BOOTSCRIPT"
log "  ✓ 开机脚本已安装到 $BOOTSCRIPT"

# 配置 install-recovery.sh 调用开机脚本
if [ -f "$RECOVERY" ] && [ ! -f "${RECOVERY}.bak_v4" ]; then
    cp "$RECOVERY" "${RECOVERY}.bak_v4"
    log "  已备份原始 install-recovery.sh"
fi

cat > "$RECOVERY" << 'RECEOF'
#!/system/bin/sh
# AutoKit 开机钩子 v4 (自动生成)

# 执行AutoKit修复脚本(后台,不阻塞启动)
SCRIPT="/system/bin/autokit_onboot.sh"
if [ -x "$SCRIPT" ]; then
    (sh "$SCRIPT") &
fi

# 调用原始recovery脚本(如果有)
ORIG="/system/etc/install-recovery.sh.bak_v4"
if [ -f "$ORIG" ]; then
    sh "$ORIG"
fi
RECEOF

chmod 755 "$RECOVERY"
chown 0:0 "$RECOVERY"
log "  ✓ install-recovery.sh 已配置"

# ---- Step 8: 恢复只读 + 触发首次优化 ----
log ""
log "[8/8] 完成安装..."
mount -o ro,remount /system 2>/dev/null

# 触发首次dexopt (pm install会自动做)
log "  触发 dexopt..."
pm install -r "$TARGET" 2>/dev/null
INSTALL_RESULT=$?
log "  pm install 结果: $INSTALL_RESULT"

# 确认安装成功
sleep 2
FINAL=$(pm path $PKG 2>/dev/null)
FINAL_SYS=$(pm list packages -s 2>/dev/null | grep phonemirror)
log "  安装路径: $FINAL"
log "  系统应用: $FINAL_SYS"

# 检查dalvik缓存已生成
DCACHE=$(ls /data/dalvik-cache/*phonemirror* /data/dalvik-cache/*AutoKit* 2>/dev/null | wc -l)
log "  dalvik缓存条目: $DCACHE"

log ""
log "============================================"
if [ -n "$FINAL" ]; then
    log " ✓ 修复完成!"
    log ""
    log " AutoKit 已部署为系统应用 + 白名单保护"
    log " 开机自动修复脚本已安装"
    log ""
    log " 接下来请:"
    log "   1. 完全断电再开机测试(断电瓶30秒)"
    log "   2. 开机后等20秒观察AutoKit是否自启"
    log "   3. 重复3次冷启动确认稳定"
    log ""
    log " 现在尝试启动AutoKit..."
    am start -n "$ACT" 2>/dev/null
else
    log " ✗ 安装可能未成功!"
    log "   请检查日志: /sdcard/autokit_fix_v4.log"
fi
log "============================================"
log ""
log "日志文件: /sdcard/autokit_fix_v4.log"
