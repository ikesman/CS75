#!/system/bin/sh
echo "=== Boot Log ==="
cat /data/local/tmp/autokit_boot.log 2>/dev/null || echo "(no log)"
echo ""
echo "=== install-recovery.sh ==="
cat /system/etc/install-recovery.sh
echo ""
echo "=== Boot script ==="
ls -la /system/bin/autokit_onboot.sh 2>/dev/null || echo "(not found)"
echo ""
echo "=== Whitelist ==="
cat /system/usr/bootwhitelist.txt
echo ""
echo "=== System APK ==="
ls -la /system/priv-app/AutoKit*
echo ""
echo "=== Package path ==="
pm path cn.manstep.phonemirrorBox
echo ""
echo "=== Dalvik cache ==="
ls -la /data/dalvik-cache/ | grep -i 'auto\|phonemirror'
echo ""
echo "=== Process ==="
ps | grep phonemirror | grep -v grep
echo ""
echo "=== Logcat crashes ==="
logcat -d | grep -i 'phonemirror\|AutoKit' | grep -i 'fatal\|crash\|exception\|error\|dexopt\|unable' | tail -20
echo ""
echo "=== Logcat ActivityManager ==="
logcat -d | grep -i 'phonemirror' | grep ActivityManager | tail -20
echo ""
echo "=== Data dir ==="
ls -la /data/data/cn.manstep.phonemirrorBox/ 2>/dev/null || echo "(no data dir)"
echo ""
echo "=== App lib ==="
ls -la /data/app-lib/cn.manstep.phonemirrorBox*/ 2>/dev/null || echo "(no app-lib)"
echo "=== DONE ==="
