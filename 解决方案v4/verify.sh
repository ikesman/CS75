#!/system/bin/sh
echo "=== FINAL DEPLOY CHECK ==="
echo ""
echo "[1] System APK:"
ls -la /system/priv-app/AutoKit.apk
echo ""
echo "[2] Dalvik cache:"
ls -la /data/dalvik-cache/*AutoKit* /data/dalvik-cache/*phonemirror* 2>/dev/null
echo ""
echo "[3] Backup:"
ls -la /system/autokit_backup/
echo ""
echo "[4] Whitelist:"
cat /system/usr/bootwhitelist.txt
echo ""
echo "[5] Boot script (first 5 lines):"
sed -n '1,5p' /system/bin/autokit_onboot.sh
echo ""
echo "[6] install-recovery.sh:"
cat /system/etc/install-recovery.sh
echo ""
echo "[7] Package:"
pm path cn.manstep.phonemirrorBox
echo ""
echo "[8] Process:"
ps | grep phonemirror | grep -v grep
echo ""
echo "[9] Test launch:"
am start -n cn.manstep.phonemirrorBox/.CheckActivity 2>&1
echo ""
echo "=== ALL GOOD ==="
