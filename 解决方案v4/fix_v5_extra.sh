#!/system/bin/sh
# 补充：确保system版dalvik缓存也被备份
mount -o rw,remount /system

DCACHE="/data/dalvik-cache"
BACKUP="/system/autokit_backup"

echo "=== Current dalvik cache ==="
ls -la $DCACHE/*AutoKit* $DCACHE/*phonemirror* 2>/dev/null

# 如果system版缓存不存在，用dexopt手动创建
SYS_DEX="$DCACHE/system@priv-app@AutoKit.apk@classes.dex"
if [ ! -f "$SYS_DEX" ]; then
    echo "Creating system dex cache..."
    # 复制data版作为system版(相同APK内容)
    DATA_DEX="$DCACHE/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"
    if [ -f "$DATA_DEX" ]; then
        cp "$DATA_DEX" "$SYS_DEX"
        chown system:all_a38 "$SYS_DEX"
        chmod 644 "$SYS_DEX"
        echo "Created $SYS_DEX from data copy"
    fi
fi

# 备份两个版本
mkdir -p "$BACKUP"
if [ -f "$SYS_DEX" ]; then
    cp "$SYS_DEX" "$BACKUP/autokit_sys.dex"
    echo "Backed up system dex"
fi

DATA_DEX="$DCACHE/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"
if [ -f "$DATA_DEX" ]; then
    cp "$DATA_DEX" "$BACKUP/autokit_data.dex"
    echo "Backed up data dex"
fi

echo ""
echo "=== Backup contents ==="
ls -la $BACKUP/

mount -o ro,remount /system
echo "=== Done ==="
