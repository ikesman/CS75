#!/system/bin/sh
echo "=== Dalvik cache full listing ==="
ls -la /data/dalvik-cache/ | grep -c '.dex'
echo "total dex files above"
echo ""
echo "=== System priv-app all ==="
ls -la /system/priv-app/
echo ""
echo "=== Dalvik for priv-app ==="
ls -la /data/dalvik-cache/system@priv-app* 2>/dev/null
echo ""
echo "=== Dalvik for data@app ==="
ls -la /data/dalvik-cache/data@app* 2>/dev/null
echo ""
echo "=== Check if AutoKit dalvik exists ==="
ls -la /data/dalvik-cache/*AutoKit* 2>/dev/null || echo "NO AutoKit dalvik cache"
ls -la /data/dalvik-cache/*phonemirror* 2>/dev/null || echo "NO phonemirror dalvik cache"
echo ""
echo "=== /data free space ==="
df /data 2>/dev/null
echo ""
echo "=== init scripts that mention dalvik or cache ==="
grep -rl 'dalvik\|dexopt\|cache' /system/etc/init* /init* 2>/dev/null
echo ""
echo "=== Check for clean scripts ==="
grep -rl 'dalvik-cache\|rm.*dex\|clean' /system/bin/ /system/xbin/ /system/etc/ 2>/dev/null
echo ""
echo "=== pm path detail ==="
pm path cn.manstep.phonemirrorBox
echo ""
echo "=== dumpsys package flags ==="
dumpsys package cn.manstep.phonemirrorBox | grep -i 'codePath\|resourcePath\|nativeLibrary\|flags\|version\|dataDir\|install\|dexopt'
echo "=== DONE ==="
