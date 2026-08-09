#!/system/bin/sh
# Fix AutoKit system app - correct ownership and permissions
echo "=== Fixing AutoKit system app ==="

mount -o rw,remount /system

# Clean up old dalvik cache
rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
rm -rf /data/data/cn.manstep.phonemirrorBox 2>/dev/null
rm -f /data/app/cn.manstep.phonemirrorBox* 2>/dev/null
echo "[1] Cleaned old data and cache"

# Fix ownership and rename to simpler name
SRC="/system/priv-app/AutoKit_2022.11.15.1535.apk"
DST="/system/priv-app/AutoKit.apk"

if [ -f "$SRC" ]; then
    mv "$SRC" "$DST"
    echo "[2] Renamed to AutoKit.apk"
elif [ -f "$DST" ]; then
    echo "[2] AutoKit.apk already exists"
else
    echo "[2] ERROR: No AutoKit APK found in priv-app!"
    exit 1
fi

# Fix ownership and permissions (CRITICAL!)
chown root:root "$DST"
chmod 644 "$DST"
echo "[3] Fixed ownership: $(ls -la $DST)"

# Compare with other priv-app files
echo "[4] Reference (other priv-app files):"
ls -la /system/priv-app/CS75PhoneProvider.apk 2>/dev/null
ls -la /system/priv-app/S301BtPhone.apk 2>/dev/null

mount -o ro,remount /system
echo "[5] /system remounted read-only"

# Manually trigger dexopt
echo "[6] Running dexopt..."
dexopt --dex /system/priv-app/AutoKit.apk 2>/dev/null
# Alternative: use pm install to trigger dexopt
pm install -r /system/priv-app/AutoKit.apk 2>/dev/null
echo "    pm install result: $?"

# Wait for dexopt to finish
sleep 3

# Check dalvik cache
echo "[7] Dalvik cache:"
ls -la /data/dalvik-cache/*AutoKit* /data/dalvik-cache/*phonemirror* 2>/dev/null

# Check package
echo "[8] Package info:"
pm path cn.manstep.phonemirrorBox 2>/dev/null
pm list packages -s 2>/dev/null | grep phonemirror

# Launch
echo "[9] Launching AutoKit..."
am start -n cn.manstep.phonemirrorBox/.CheckActivity 2>/dev/null

sleep 3

# Check if running
echo "[10] Process status:"
ps 2>/dev/null | grep phonemirror

echo ""
echo "=== Fix complete ==="
