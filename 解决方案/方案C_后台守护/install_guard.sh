#!/system/bin/sh
# ============================================
# 注册守护脚本为开机自启动
# 需要Root权限
# ============================================

GUARD_SCRIPT="/data/local/tmp/autokit_guard.sh"
GUARD_SOURCE="/sdcard/autokit_guard.sh"

echo "=============================="
echo " AutoKit 守护进程安装工具"
echo "=============================="

# 复制守护脚本
if [ -f "$GUARD_SOURCE" ]; then
    cp "$GUARD_SOURCE" "$GUARD_SCRIPT"
    chmod 755 "$GUARD_SCRIPT"
    echo "[OK] 守护脚本已安装到 $GUARD_SCRIPT"
else
    echo "错误：请将 autokit_guard.sh 复制到 /sdcard/"
    exit 1
fi

# 创建开机自启动钩子
# 方法1：通过install-recovery.sh（大多数车机支持）
mount -o rw,remount /system 2>/dev/null

RECOVERY_SCRIPT="/system/etc/install-recovery.sh"

if [ -f "$RECOVERY_SCRIPT" ]; then
    # 备份已有的脚本
    cp "$RECOVERY_SCRIPT" "${RECOVERY_SCRIPT}.bak"
    echo "[备份] 已备份原始 install-recovery.sh"
fi

cat > "$RECOVERY_SCRIPT" << 'SCRIPT_EOF'
#!/system/bin/sh
# AutoKit 开机自启守护
GUARD="/data/local/tmp/autokit_guard.sh"
if [ -f "$GUARD" ]; then
    # 等待系统完全启动
    sleep 10
    # 后台运行守护脚本
    nohup sh "$GUARD" > /dev/null 2>&1 &
fi
SCRIPT_EOF

chmod 755 "$RECOVERY_SCRIPT"
mount -o ro,remount /system 2>/dev/null

echo "[OK] 开机自启配置完成"
echo ""
echo "现在手动启动守护进程..."
nohup sh "$GUARD_SCRIPT" > /dev/null 2>&1 &
echo "[OK] 守护进程已在后台运行 (PID: $!)"
echo ""
echo "=============================="
echo "安装完成！守护进程会在以下场景自动修复AutoKit："
echo "  1. Quick Boot唤醒后"
echo "  2. APP闪退后"
echo "  3. APP进程被杀后"
echo ""
echo "如需卸载守护："
echo "  rm /data/local/tmp/autokit_guard.sh"
echo "  mount -o rw,remount /system"
echo "  rm /system/etc/install-recovery.sh"
echo "  mount -o ro,remount /system"
echo "=============================="
