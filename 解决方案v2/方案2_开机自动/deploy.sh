#!/system/bin/sh
# ============================================
# 部署开机自动覆盖安装（一次性执行）
# 需要Root权限
# ============================================

BOOT_SCRIPT="/data/local/tmp/autokit_boot_reinstall.sh"
BOOT_SOURCE="/sdcard/autokit_boot_reinstall.sh"
APK_FILE="/sdcard/AutoKit_2022.11.15.1535.apk"

echo "=============================="
echo " AutoKit 开机自动修复 - 部署工具"
echo "=============================="
echo ""

# 检查APK
if [ ! -f "$APK_FILE" ]; then
    echo "[错误] 请先将 AutoKit_2022.11.15.1535.apk 复制到 /sdcard/"
    exit 1
fi
echo "[OK] APK文件已就位"

# 检查启动脚本源文件
if [ ! -f "$BOOT_SOURCE" ]; then
    echo "[错误] 请先将 autokit_boot_reinstall.sh 复制到 /sdcard/"
    exit 1
fi

# 安装启动脚本
cp "$BOOT_SOURCE" "$BOOT_SCRIPT"
chmod 755 "$BOOT_SCRIPT"
echo "[OK] 启动脚本已部署到 $BOOT_SCRIPT"

# 挂载system为可写
mount -o rw,remount /system 2>/dev/null
if [ $? -ne 0 ]; then
    echo "[警告] 无法挂载/system为可写"
    echo "尝试备选方案..."
    
    # 备选：使用 /data/local/tmp 下的方式
    # 通过写入 .sh 到 /data/local/userinit.d/ (某些ROM支持)
    mkdir -p /data/local/userinit.d 2>/dev/null
    
    cat > /data/local/userinit.d/99-autokit.sh << 'INNER_EOF'
#!/system/bin/sh
sh /data/local/tmp/autokit_boot_reinstall.sh &
INNER_EOF
    chmod 755 /data/local/userinit.d/99-autokit.sh
    echo "[OK] 已写入 userinit.d (备选方案)"
    echo ""
    echo "[重要] 如果重启后没有自动安装，说明此车机不支持userinit.d"
    echo "需要使用方案3（守护APK）"
    exit 0
fi

# 写入 install-recovery.sh
RECOVERY="/system/etc/install-recovery.sh"

# 备份
if [ -f "$RECOVERY" ]; then
    cp "$RECOVERY" "${RECOVERY}.bak.$(date +%s)"
    echo "[备份] 已备份原 install-recovery.sh"
fi

cat > "$RECOVERY" << 'EOF'
#!/system/bin/sh
# AutoKit 开机自动覆盖安装
SCRIPT="/data/local/tmp/autokit_boot_reinstall.sh"
if [ -f "$SCRIPT" ]; then
    (sleep 5 && sh "$SCRIPT") &
fi
EOF

chmod 755 "$RECOVERY"
mount -o ro,remount /system 2>/dev/null

echo "[OK] 开机自启已配置"
echo ""

# 立即执行一次测试
echo "现在执行一次覆盖安装测试..."
sh "$BOOT_SCRIPT"

echo ""
echo "=============================="
echo " 部署完成！"
echo ""
echo " 每次开机后将自动："
echo "   1. 等待系统就绪"
echo "   2. 覆盖安装AutoKit（修复dalvik缓存）"
echo "   3. 自动启动AutoKit"
echo ""
echo " 日志文件: /data/local/tmp/autokit_boot.log"
echo ""
echo " 如需卸载："
echo "   rm /data/local/tmp/autokit_boot_reinstall.sh"
echo "   mount -o rw,remount /system"
echo "   rm /system/etc/install-recovery.sh"
echo "   mount -o ro,remount /system"
echo "=============================="
