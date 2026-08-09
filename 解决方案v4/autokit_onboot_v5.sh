#!/system/bin/sh
# AutoKit 极速开机修复 v5 (final)
# 秒速恢复dalvik缓存 + 自动启动
LOG=/data/local/tmp/autokit_boot.log
PKG=cn.manstep.phonemirrorBox
ACT=cn.manstep.phonemirrorBox/.CheckActivity
SYSAPK=/system/priv-app/AutoKit.apk
BACKUP=/system/autokit_backup
DCACHE=/data/dalvik-cache

log() { echo "$(date) $1" >> $LOG; }
log "===== v5 boot script started ====="

# 等系统就绪
N=0
while [ $N -lt 60 ]; do
    pm list packages >/dev/null 2>&1 && break
    sleep 1
    N=$((N+1))
done
log "system ready after ${N}s"

# 检查dalvik缓存
SYS_DEX="$DCACHE/system@priv-app@AutoKit.apk@classes.dex"
DATA_DEX="$DCACHE/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"

NEED_FIX=0
if [ ! -f "$SYS_DEX" ] && [ ! -f "$DATA_DEX" ]; then
    NEED_FIX=1
    log "dalvik cache missing!"
elif [ ! -f "$DATA_DEX" ]; then
    # data版缓存可能也需要
    NEED_FIX=1
    log "data dalvik cache missing!"
fi

if [ "$NEED_FIX" -eq 1 ]; then
    log "restoring dalvik cache from backup..."
    
    # 秒速恢复: 直接cp备份的dex
    if [ -f "$BACKUP/autokit_sys.dex" ] && [ ! -f "$SYS_DEX" ]; then
        cp "$BACKUP/autokit_sys.dex" "$SYS_DEX"
        chown 1000:10038 "$SYS_DEX"
        chmod 644 "$SYS_DEX"
        log "restored system dex (cp)"
    fi
    
    if [ -f "$BACKUP/autokit_data.dex" ] && [ ! -f "$DATA_DEX" ]; then
        cp "$BACKUP/autokit_data.dex" "$DATA_DEX"
        chown 1000:10038 "$DATA_DEX"
        chmod 644 "$DATA_DEX"
        log "restored data dex (cp)"
    fi
    
    # 如果连备份都没有，回退到pm install
    if [ ! -f "$BACKUP/autokit_sys.dex" ] && [ ! -f "$BACKUP/autokit_data.dex" ]; then
        log "no backup, falling back to pm install..."
        pm install -r "$SYSAPK" 2>/dev/null
        log "pm install result: $?"
        sleep 3
    fi
else
    log "dalvik cache OK"
fi

# 确认已安装
sleep 1
INSTALLED=$(pm path $PKG 2>/dev/null)
log "pkg path: $INSTALLED"

if [ -z "$INSTALLED" ]; then
    log "package not found, force install..."
    pm install -r "$SYSAPK" 2>/dev/null
    log "force install result: $?"
    sleep 3
fi

# 启动AutoKit
am start -n "$ACT" 2>/dev/null
log "launched AutoKit, result: $?"
log "===== v5 boot script done ====="
