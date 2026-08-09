#!/system/bin/sh
# ============================================
# AutoKit 终极修复 v5
# 
# 核心改进：预存dalvik缓存，开机秒速恢复
# 不再需要76秒的pm install
# ============================================

echo "============================================"
echo " AutoKit 终极修复 v5"
echo "============================================"

mount -o rw,remount /system

PKG="cn.manstep.phonemirrorBox"
SYSAPK="/system/priv-app/AutoKit.apk"
DCACHE_DIR="/data/dalvik-cache"
DCACHE_SYS="$DCACHE_DIR/system@priv-app@AutoKit.apk@classes.dex"
DCACHE_DATA="$DCACHE_DIR/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"
BACKUP_DIR="/system/autokit_backup"

# Step 1: 卸载用户版(data/app中的副本)，只保留系统版
echo ""
echo "[1/7] 清理用户版副本..."
# pm uninstall会删除用户更新但保留系统应用
pm uninstall $PKG 2>/dev/null
# 如果still存在(系统版保留)，清理data/app中的副本
rm -f /data/app/cn.manstep.phonemirrorBox* 2>/dev/null
rm -f /data/app/$PKG* 2>/dev/null
rm -f $DCACHE_DATA 2>/dev/null
rm -rf /data/data/$PKG 2>/dev/null
echo "  已清理用户版副本"

# Step 2: 确认系统APK存在且权限正确
echo ""
echo "[2/7] 验证系统APK..."
if [ ! -f "$SYSAPK" ]; then
    echo "  ERROR: $SYSAPK 不存在!"
    exit 1
fi
chown root:root "$SYSAPK"
chmod 644 "$SYSAPK"
echo "  $(ls -la $SYSAPK)"

# Step 3: 重新生成dalvik缓存(只做一次)
echo ""
echo "[3/7] 生成 dalvik 缓存（可能需70秒）..."
rm -f $DCACHE_SYS 2>/dev/null
# 用pm install -r触发dexopt，但作为系统app
pm install -r "$SYSAPK" 2>/dev/null
echo "  pm install 完成"

# 等待缓存生成
sleep 2

# Step 4: 备份dalvik缓存到/system/（不会被冷启动清除）
echo ""
echo "[4/7] 备份 dalvik 缓存到 /system/..."
mkdir -p "$BACKUP_DIR"

# 检查哪个缓存文件现在存在
if [ -f "$DCACHE_SYS" ]; then
    cp "$DCACHE_SYS" "$BACKUP_DIR/autokit_sys.dex"
    echo "  已备份 system dex: $(ls -la $BACKUP_DIR/autokit_sys.dex)"
fi
if [ -f "$DCACHE_DATA" ]; then
    cp "$DCACHE_DATA" "$BACKUP_DIR/autokit_data.dex"
    echo "  已备份 data dex: $(ls -la $BACKUP_DIR/autokit_data.dex)"
fi

# 也记录当前的包路径
pm path $PKG > "$BACKUP_DIR/pkg_path.txt" 2>/dev/null
cat "$BACKUP_DIR/pkg_path.txt"

# Step 5: 确保白名单
echo ""
echo "[5/7] 确认白名单..."
if ! grep -q "$PKG" /system/usr/bootwhitelist.txt 2>/dev/null; then
    echo "$PKG" >> /system/usr/bootwhitelist.txt
    echo "  已添加到白名单"
else
    echo "  已在白名单中"
fi

# Step 6: 安装新的极速开机脚本
echo ""
echo "[6/7] 安装极速开机脚本..."
cat > /system/bin/autokit_onboot.sh << 'BOOTEOF'
#!/system/bin/sh
# AutoKit 极速开机修复 v5
# 秒速恢复dalvik缓存，不再需要76秒的pm install
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

NEED_RESTORE=0
if [ ! -f "$SYS_DEX" ] && [ ! -f "$DATA_DEX" ]; then
    NEED_RESTORE=1
    log "dalvik cache missing!"
fi

if [ "$NEED_RESTORE" -eq 1 ]; then
    log "restoring dalvik cache from backup..."
    
    # 秒速恢复：直接复制备份的dex文件
    if [ -f "$BACKUP/autokit_sys.dex" ]; then
        cp "$BACKUP/autokit_sys.dex" "$SYS_DEX"
        chown system:all_a38 "$SYS_DEX"
        chmod 644 "$SYS_DEX"
        log "restored system dex"
    fi
    
    if [ -f "$BACKUP/autokit_data.dex" ]; then
        cp "$BACKUP/autokit_data.dex" "$DATA_DEX"
        chown system:all_a38 "$DATA_DEX"
        chmod 644 "$DATA_DEX"
        log "restored data dex"
    fi
    
    # 如果没有备份，回退到pm install
    if [ ! -f "$BACKUP/autokit_sys.dex" ] && [ ! -f "$BACKUP/autokit_data.dex" ]; then
        log "no backup found, falling back to pm install..."
        pm install -r "$SYSAPK" 2>/dev/null
        log "pm install result: $?"
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
    sleep 2
fi

# 启动AutoKit
am start -n "$ACT" 2>/dev/null
log "launched AutoKit"
log "===== v5 boot script done ====="
BOOTEOF
chmod 755 /system/bin/autokit_onboot.sh
chown root:root /system/bin/autokit_onboot.sh
echo "  已安装极速开机脚本"

# Step 7: 确认install-recovery.sh正确
echo ""
echo "[7/7] 确认启动钩子..."
cat /system/etc/install-recovery.sh | grep -q autokit_onboot
if [ $? -eq 0 ]; then
    echo "  启动钩子已存在"
else
    cat > /system/etc/install-recovery.sh << 'RECEOF'
#!/system/bin/sh
/system/bin/su --daemon &
/system/bin/360s --daemon 8005&

# AutoKit boot fix v5
if [ -x /system/bin/autokit_onboot.sh ]; then
    /system/bin/autokit_onboot.sh &
fi
RECEOF
    chmod 755 /system/etc/install-recovery.sh
    echo "  启动钩子已配置"
fi

mount -o ro,remount /system

echo ""
echo "============================================"
echo " 修复完成!"
echo ""
echo " 当前状态:"
echo "  APK: $(ls -la $SYSAPK 2>/dev/null)"
pm path $PKG
echo "  进程: $(ps | grep phonemirror | grep -v grep)"
echo ""
echo " 备份缓存:"
ls -la "$BACKUP_DIR/" 2>/dev/null
echo ""
echo " 请断电重启测试！"
echo "============================================"
