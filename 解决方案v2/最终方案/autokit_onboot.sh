#!/system/bin/sh
# ============================================
# AutoKit 开机自动覆盖安装+启动
# 在 /system/etc/install-recovery.sh 中调用
# ============================================

PKG="cn.manstep.phonemirrorBox"
ACT="cn.manstep.phonemirrorBox/.CheckActivity"
APK="/sdcard/AutoKit_2022.11.15.1535.apk"
LOG="/data/local/tmp/autokit.log"

log() { echo "$(date '+%m-%d %H:%M:%S') $1" >> "$LOG" 2>/dev/null; }

log "===== autokit_onboot started ====="

# 等待包管理器就绪（最多60秒）
N=0
while [ $N -lt 60 ]; do
    pm list packages 2>/dev/null | grep -q "$PKG" && break
    sleep 1
    N=$((N+1))
done
log "pm ready after ${N}s"

# 等待sdcard可访问
N=0
while [ $N -lt 30 ]; do
    [ -f "$APK" ] && break
    sleep 1
    N=$((N+1))
done

if [ ! -f "$APK" ]; then
    log "APK not found: $APK, try start directly"
    am start -n "$ACT" 2>/dev/null
    exit 1
fi

# 杀残留
am force-stop "$PKG" 2>/dev/null
sleep 1

# 删除dalvik-cache中旧的odex（如果有）
# 路径格式: /data/dalvik-cache/data@app@cn.manstep.phonemirrorBox-N.apk@classes.dex
rm -f /data/dalvik-cache/*phonemirrorBox* 2>/dev/null
log "dalvik-cache cleaned"

# 覆盖安装：这会触发新的dexopt
RESULT=$(pm install -r -d "$APK" 2>&1)
log "install result: $RESULT"

sleep 2

# 启动
am start -n "$ACT" 2>/dev/null
log "app launched"
log "===== autokit_onboot done ====="
