#!/system/bin/sh
# === FULL SYSTEM DIAGNOSTIC v6 ===
echo "========================================"
echo " FULL DIAGNOSTIC $(date)"
echo "========================================"

echo ""
echo "[1] Boot log"
cat /data/local/tmp/autokit_boot.log 2>/dev/null || echo "(no log - script never ran!)"

echo ""
echo "[2] install-recovery.sh"
cat /system/etc/install-recovery.sh 2>/dev/null || echo "(NOT FOUND!)"

echo ""
echo "[3] Boot script"
ls -la /system/bin/autokit_onboot.sh 2>/dev/null || echo "(NOT FOUND!)"

echo ""
echo "[4] System APK"
ls -la /system/priv-app/AutoKit* 2>/dev/null || echo "(NOT FOUND!)"

echo ""
echo "[5] Backup dir"
ls -la /system/autokit_backup/ 2>/dev/null || echo "(NOT FOUND!)"

echo ""
echo "[6] Whitelist"
cat /system/usr/bootwhitelist.txt 2>/dev/null || echo "(NOT FOUND!)"

echo ""
echo "[7] ALL dalvik cache"
ls -la /data/dalvik-cache/ | grep -i 'auto\|phonemirror'
echo "total entries: $(ls /data/dalvik-cache/*.dex 2>/dev/null | grep -c dex)"

echo ""
echo "[8] Package status"
pm path cn.manstep.phonemirrorBox 2>/dev/null || echo "(not installed)"
pm list packages 2>/dev/null | grep phonemirror

echo ""
echo "[9] /data/app"
ls -la /data/app/ | grep -i 'phonemirror\|autokit\|manstep'
echo "(all data/app entries):"
ls /data/app/

echo ""
echo "[10] /data/data app dir"
ls -la /data/data/cn.manstep.phonemirrorBox/ 2>/dev/null || echo "(no data dir)"

echo ""
echo "[11] Process"
ps | grep phonemirror | grep -v grep

echo ""
echo "[12] Try launch now"
am start -n cn.manstep.phonemirrorBox/.CheckActivity 2>&1

echo ""
echo "[13] Logcat errors"
logcat -d 2>/dev/null | grep -i 'phonemirror\|AutoKit' | grep -i 'fatal\|crash\|error\|unable\|dexopt\|exception' | grep -v grep

echo ""
echo "[14] dmesg related"
dmesg | grep -i 'dalvik\|dex\|autokit\|phonemirror' 2>/dev/null

echo ""
echo "[15] /system timestamps check"
echo "Factory apps timestamp:"
ls -la /system/priv-app/CS75Can.apk 2>/dev/null
echo "AutoKit timestamp:"
ls -la /system/priv-app/AutoKit.apk 2>/dev/null

echo ""
echo "[16] System partition mount"
mount | grep system

echo ""
echo "[17] Uptime"
cat /proc/uptime

echo ""
echo "[18] Last boot reason"
getprop ro.boot.mode 2>/dev/null
getprop sys.boot.reason 2>/dev/null
getprop ro.quickboot.enable 2>/dev/null

echo ""
echo "========================================"
echo " DIAGNOSTIC COMPLETE"
echo "========================================"
