#!/system/bin/sh
# Update boot script to match renamed APK
mount -o rw,remount /system

cat > /system/bin/autokit_onboot.sh << 'BOOTEOF'
#!/system/bin/sh
LOG=/data/local/tmp/autokit_boot.log
PKG=cn.manstep.phonemirrorBox
ACT=cn.manstep.phonemirrorBox/.CheckActivity
APK_SYS=/system/priv-app/AutoKit.apk

log() { echo "$(date) $1" >> $LOG; }
log "===== boot script started ====="

N=0
while [ $N -lt 90 ]; do
    pm list packages 2>/dev/null | grep -q phonemirror && break
    sleep 1
    N=$((N+1))
done
log "pm ready after ${N}s"

INSTALLED=$(pm path $PKG 2>/dev/null)
log "installed: $INSTALLED"

if [ -z "$INSTALLED" ]; then
    log "not installed, repairing..."
    rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
    rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
    pm install -r $APK_SYS 2>/dev/null
    log "reinstall result: $?"
    sleep 3
fi

# Check dalvik cache exists (critical for cold boot)
DCACHE=$(ls /data/dalvik-cache/*AutoKit* /data/dalvik-cache/*phonemirror* 2>/dev/null | wc -l)
if [ "$DCACHE" -eq 0 ]; then
    log "dalvik cache missing, refreshing..."
    pm install -r $APK_SYS 2>/dev/null
    log "dexopt refresh result: $?"
    sleep 3
fi

INSTALLED=$(pm path $PKG 2>/dev/null)
if [ -n "$INSTALLED" ]; then
    log "launching AutoKit"
    am start -n $ACT 2>/dev/null
    log "launch result: $?"
else
    log "FAILED to install AutoKit!"
fi
log "===== boot script done ====="
BOOTEOF

chmod 755 /system/bin/autokit_onboot.sh
chown root:root /system/bin/autokit_onboot.sh
echo "[OK] Boot script updated"
cat /system/bin/autokit_onboot.sh

mount -o ro,remount /system
echo "[OK] Done"
