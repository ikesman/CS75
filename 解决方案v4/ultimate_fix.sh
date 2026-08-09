#!/system/bin/sh
# ============================================================
# AutoKit 终极修复部署脚本 v6
# 通过ADB远程执行，一次性完成所有修复
# 用法: adb shell "su -c 'sh /data/local/tmp/ultimate_fix.sh'"
# ============================================================

LOG=/data/local/tmp/autokit_fix.log
PKG=cn.manstep.phonemirrorBox
SYSAPK=/system/priv-app/AutoKit.apk
BACKUP=/system/autokit_backup
DCACHE=/data/dalvik-cache
APPLIB=/data/app-lib/cn.manstep.phonemirrorBox-1
DATAAPK=/data/app/cn.manstep.phonemirrorBox-1.apk

log() { echo "$(date) $1" >> $LOG; echo "$1"; }

log "========== 终极修复 v6 开始 =========="

# ---- 第1步: 确保system可写 ----
mount -o remount,rw /system 2>/dev/null
if [ $? -ne 0 ]; then
    log "[FATAL] 无法挂载/system为可写!"
    exit 1
fi
log "[1/8] /system 已挂载为可写"

# ---- 第2步: 验证system APK ----
if [ ! -f "$SYSAPK" ]; then
    log "[FATAL] $SYSAPK 不存在!"
    exit 1
fi
log "[2/8] system APK 存在 ($(ls -la $SYSAPK))"

# ---- 第3步: 确保pm install已完成（提取native库） ----
CURRENT_PATH=$(pm path $PKG 2>/dev/null)
log "[3/8] 当前包路径: $CURRENT_PATH"

if [ ! -d "$APPLIB" ] || [ -z "$(ls $APPLIB 2>/dev/null)" ]; then
    log "[3/8] native库目录缺失，执行pm install..."
    pm install -r "$SYSAPK" 2>/dev/null
    log "[3/8] pm install 结果: $?"
    sleep 2
fi

# 验证native库
if [ -d "$APPLIB" ]; then
    SO_COUNT=$(ls "$APPLIB"/*.so 2>/dev/null | grep -c '.so')
    log "[3/8] native库数量: $SO_COUNT"
else
    log "[FATAL] pm install后仍然没有native库!"
    exit 1
fi

# ---- 第4步: 创建/system备份目录 ----
mkdir -p "$BACKUP/native_libs" 2>/dev/null
log "[4/8] 备份目录就绪"

# ---- 第5步: 备份native .so库到/system（持久化） ----
for SO in "$APPLIB"/*.so; do
    SONAME=$(basename "$SO")
    cp "$SO" "$BACKUP/native_libs/$SONAME"
    chmod 755 "$BACKUP/native_libs/$SONAME"
    chown 1000:1000 "$BACKUP/native_libs/$SONAME"
    log "[5/8] 备份 $SONAME"
done
log "[5/8] native库备份完成"

# ---- 第6步: 备份dalvik cache ----
SYS_DEX="$DCACHE/system@priv-app@AutoKit.apk@classes.dex"
DATA_DEX="$DCACHE/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"

if [ -f "$SYS_DEX" ]; then
    cp "$SYS_DEX" "$BACKUP/autokit_sys.dex"
    log "[6/8] 备份system dalvik cache"
fi

if [ -f "$DATA_DEX" ]; then
    cp "$DATA_DEX" "$BACKUP/autokit_data.dex"
    log "[6/8] 备份data dalvik cache"
fi

# 记录dalvik cache的ownership
if [ -f "$DATA_DEX" ]; then
    ls -la "$DATA_DEX" > "$BACKUP/dex_info.txt"
fi
log "[6/8] dalvik cache备份完成"

# ---- 第7步: 备份data/app APK ----
if [ -f "$DATAAPK" ]; then
    cp "$DATAAPK" "$BACKUP/data_app.apk"
    log "[7/8] 备份data APK"
else
    log "[7/8] data APK不存在，跳过"
fi

# ---- 第8步: 部署boot脚本 ----
# 写入boot脚本
cat > /system/bin/autokit_onboot.sh << 'BOOTEOF'
#!/system/bin/sh
# AutoKit 极速开机脚本 v6
# 核心策略: 恢复native库 + dalvik缓存 + 包注册 → 秒开
LOG=/data/local/tmp/autokit_boot.log
PKG=cn.manstep.phonemirrorBox
ACT=cn.manstep.phonemirrorBox/.CheckActivity
SYSAPK=/system/priv-app/AutoKit.apk
BACKUP=/system/autokit_backup
DCACHE=/data/dalvik-cache
APPLIB=/data/app-lib/cn.manstep.phonemirrorBox-1
DATAAPK=/data/app/cn.manstep.phonemirrorBox-1.apk

log() { echo "$(date) $1" >> $LOG; }
log "===== v6 boot script started ====="

# 开启WiFi ADB
setprop service.adb.tcp.port 5555
stop adbd 2>/dev/null
start adbd 2>/dev/null
log "ADB on 5555"

# 等PackageManager就绪
N=0
while [ $N -lt 90 ]; do
    pm list packages >/dev/null 2>&1 && break
    sleep 1
    N=$((N+1))
done
log "pm ready after ${N}s"

# === 核心修复: 恢复native库 ===
if [ ! -d "$APPLIB" ] || [ -z "$(ls $APPLIB/*.so 2>/dev/null)" ]; then
    log "native libs missing, restoring..."
    mkdir -p "$APPLIB"
    for SO in "$BACKUP/native_libs"/*.so; do
        SONAME=$(basename "$SO")
        cp "$SO" "$APPLIB/$SONAME"
        chmod 755 "$APPLIB/$SONAME"
        chown 1000:1000 "$APPLIB/$SONAME"
    done
    log "native libs restored"
else
    log "native libs OK"
fi

# === 恢复data lib软链接 ===
DATADIR=/data/data/$PKG
if [ -d "$DATADIR" ] && [ ! -e "$DATADIR/lib" ]; then
    ln -s "$APPLIB" "$DATADIR/lib"
    chown 9998:9998 "$DATADIR/lib"
    log "lib symlink created"
fi

# === 恢复data/app APK ===
if [ ! -f "$DATAAPK" ] && [ -f "$BACKUP/data_app.apk" ]; then
    cp "$BACKUP/data_app.apk" "$DATAAPK"
    chown 1000:1000 "$DATAAPK"
    chmod 644 "$DATAAPK"
    log "data APK restored"
fi

# === 恢复dalvik cache ===
SYS_DEX="$DCACHE/system@priv-app@AutoKit.apk@classes.dex"
DATA_DEX="$DCACHE/data@app@cn.manstep.phonemirrorBox-1.apk@classes.dex"

if [ ! -f "$DATA_DEX" ] && [ -f "$BACKUP/autokit_data.dex" ]; then
    cp "$BACKUP/autokit_data.dex" "$DATA_DEX"
    chown 1000:10038 "$DATA_DEX"
    chmod 644 "$DATA_DEX"
    log "data dex restored"
fi

if [ ! -f "$SYS_DEX" ] && [ -f "$BACKUP/autokit_sys.dex" ]; then
    cp "$BACKUP/autokit_sys.dex" "$SYS_DEX"
    chown 1000:10038 "$SYS_DEX"
    chmod 644 "$SYS_DEX"
    log "sys dex restored"
fi

# === 验证包注册 ===
INSTALLED=$(pm path $PKG 2>/dev/null)
if [ -z "$INSTALLED" ]; then
    log "package not registered, running pm install..."
    pm install -r "$SYSAPK" 2>/dev/null
    log "pm install result: $?"
    sleep 3
else
    log "package registered: $INSTALLED"
fi

# === 等待一下确保所有恢复生效 ===
sleep 1

# === 启动AutoKit ===
am start -n "$ACT" 2>/dev/null
R=$?
log "launch result: $R"

# 如果启动失败，尝试主Activity
if [ $R -ne 0 ]; then
    sleep 2
    am start -n "$PKG/.MainActivity" 2>/dev/null
    log "retry with MainActivity: $?"
fi

log "===== v6 boot script done ====="
BOOTEOF

chmod 755 /system/bin/autokit_onboot.sh
chown 0:0 /system/bin/autokit_onboot.sh
log "[8/8] boot脚本已部署"

# ---- 确认install-recovery.sh包含我们的hook ----
RECOVERY=/system/etc/install-recovery.sh
if [ -f "$RECOVERY" ]; then
    # 检查是否已包含autokit hook
    if grep -q "autokit_onboot" "$RECOVERY"; then
        log "[OK] install-recovery.sh 已包含hook"
    else
        echo "" >> "$RECOVERY"
        echo "# AutoKit boot fix" >> "$RECOVERY"
        echo "if [ -x /system/bin/autokit_onboot.sh ]; then" >> "$RECOVERY"
        echo "    /system/bin/autokit_onboot.sh &" >> "$RECOVERY"
        echo "fi" >> "$RECOVERY"
        log "[OK] install-recovery.sh hook已添加"
    fi
else
    log "[WARN] install-recovery.sh 不存在，创建新的"
    echo "#!/system/bin/sh" > "$RECOVERY"
    echo "/system/bin/su --daemon &" >> "$RECOVERY"
    echo "/system/bin/360s --daemon 8005&" >> "$RECOVERY"
    echo "" >> "$RECOVERY"
    echo "# AutoKit boot fix" >> "$RECOVERY"
    echo "if [ -x /system/bin/autokit_onboot.sh ]; then" >> "$RECOVERY"
    echo "    /system/bin/autokit_onboot.sh &" >> "$RECOVERY"
    echo "fi" >> "$RECOVERY"
    chmod 755 "$RECOVERY"
fi

# ---- remount回只读 ----
mount -o remount,ro /system 2>/dev/null

# ---- 验证最终状态 ----
log ""
log "========== 最终验证 =========="
log "system APK: $(ls -la $SYSAPK 2>/dev/null)"
log "data APK: $(ls -la $DATAAPK 2>/dev/null)"
log "native libs: $(ls $APPLIB/*.so 2>/dev/null | grep -c '.so') files"
log "backup native: $(ls $BACKUP/native_libs/*.so 2>/dev/null | grep -c '.so') files"
log "sys dex: $(ls -la $SYS_DEX 2>/dev/null)"
log "data dex: $(ls -la $DATA_DEX 2>/dev/null)"
log "backup dex: $(ls $BACKUP/*.dex 2>/dev/null)"
log "boot script: $(ls -la /system/bin/autokit_onboot.sh)"
log "recovery hook: $(grep autokit $RECOVERY 2>/dev/null)"
log "package path: $(pm path $PKG 2>/dev/null)"
log ""
log "========== 终极修复 v6 完成 =========="
log "请重启车机测试！"
