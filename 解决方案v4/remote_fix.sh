#!/system/bin/sh
# Remote fix script - executed via ADB
mount -o rw,remount /system

# Step 1: Fix whitelist
cp /system/usr/bootwhitelist.txt /system/usr/bootwhitelist.txt.bak_remote
echo 'com.incall.apps.usercenter
com.car.can
com.car.avm
com.car.cs75_voice
com.car.cs75_media
com.car.radio
cn.manstep.phonemirrorBox' > /system/usr/bootwhitelist.txt
echo "[1] Whitelist updated:"
cat /system/usr/bootwhitelist.txt

# Step 2: Verify AutoKit APK exists
echo ""
echo "[2] AutoKit APK:"
ls -la /system/priv-app/AutoKit*

# Step 3: Clean dalvik cache
rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
echo "[3] Dalvik cache cleaned"

# Step 4: Create boot script
cat > /system/bin/autokit_onboot.sh << 'BOOTEOF'
#!/system/bin/sh
LOG=/data/local/tmp/autokit_boot.log
PKG=cn.manstep.phonemirrorBox
ACT=cn.manstep.phonemirrorBox/.CheckActivity
APK_SYS=/system/priv-app/AutoKit_2022.11.15.1535.apk

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
echo "[4] Boot script installed"

# Step 5: Update install-recovery.sh
cp /system/etc/install-recovery.sh /system/etc/install-recovery.sh.bak_remote
cat > /system/etc/install-recovery.sh << 'RECEOF'
#!/system/bin/sh
/system/bin/su --daemon &
/system/bin/360s --daemon 8005&

# AutoKit boot fix
if [ -x /system/bin/autokit_onboot.sh ]; then
    /system/bin/autokit_onboot.sh &
fi
RECEOF
chmod 755 /system/etc/install-recovery.sh
echo "[5] install-recovery.sh updated:"
cat /system/etc/install-recovery.sh

# Step 6: Ensure not in blacklist
if [ -f /system/usr/bootblacklist.txt ]; then
    grep -v phonemirror /system/usr/bootblacklist.txt > /system/usr/bootblacklist.tmp
    mv /system/usr/bootblacklist.tmp /system/usr/bootblacklist.txt
    echo "[6] Blacklist checked (removed if present)"
fi

# Step 7: Remount read-only
mount -o ro,remount /system
echo "[7] /system remounted read-only"

# Step 8: Force dexopt by reinstalling
pm install -r /system/priv-app/AutoKit_2022.11.15.1535.apk 2>/dev/null
echo "[8] Triggered dexopt"

# Step 9: Check dalvik cache generated
sleep 3
echo "[9] Dalvik cache now:"
ls -la /data/dalvik-cache/*phonemirror* /data/dalvik-cache/*AutoKit* 2>/dev/null

# Step 10: Launch AutoKit
echo "[10] Launching AutoKit..."
am start -n cn.manstep.phonemirrorBox/.CheckActivity 2>/dev/null

echo ""
echo "========================================="
echo " REMOTE FIX COMPLETE"
echo "========================================="
