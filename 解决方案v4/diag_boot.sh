#!/system/bin/sh
# Check what cleans dalvik cache on boot
echo "=== Quick Boot config ==="
getprop ro.quickboot.enable
getprop ro.quickboot.time

echo "=== init scripts that mention dalvik ==="
grep -rl "dalvik" /system/etc/init* /init* 2>/dev/null
grep -rl "dalvik-cache" /system/etc/init* /init* 2>/dev/null

echo "=== init.rc dalvik references ==="
grep -n "dalvik" /init.rc /init.*.rc 2>/dev/null

echo "=== system server boot scripts ==="
ls -la /system/etc/init.d/ 2>/dev/null
cat /system/etc/init.d/* 2>/dev/null

echo "=== boot completed ==="
getprop sys.boot_completed

echo "=== check dexopt persistence ==="
ls -la /data/dalvik-cache/system@priv-app@CS75PhoneProvider.apk@classes.dex
ls -la /data/dalvik-cache/system@priv-app@AutoKit.apk@classes.dex

echo "=== /data mount info ==="
mount | grep data

echo "=== Quick boot hibernation ==="
ls -la /dev/block/mmcblk* 2>/dev/null | grep -v "p[0-9]" 
grep -r "quickboot" /system/etc/ 2>/dev/null
grep -r "hibernate" /system/etc/ 2>/dev/null

echo "=== Check if system cleans new apps on boot ==="
grep -rl "phonemirror" /data/system/ 2>/dev/null
cat /data/system/packages.xml 2>/dev/null | grep -A5 phonemirror
