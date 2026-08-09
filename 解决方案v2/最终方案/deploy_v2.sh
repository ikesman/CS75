#!/system/bin/sh
# ============================================
# 一键部署 AutoKit 开机自动修复
#
# 功能：
#   1. 将开机脚本写入系统
#   2. 每次冷启动自动覆盖安装AutoKit
#   3. 安装完成后自动打开APP
#
# 前提：
#   - Root权限（RE管理器已确认有）
#   - /sdcard/下有 AutoKit_2022.11.15.1535.apk
#   - /sdcard/下有 autokit_onboot.sh
#
# 执行方式：RE管理器 → 以Root执行此脚本
# ============================================

echo "======================================"
echo " AutoKit 开机自动修复 - 部署工具 v2"
echo "======================================"
echo ""

# ---- 检查文件 ----
APK="/sdcard/AutoKit_2022.11.15.1535.apk"
ONBOOT_SRC="/sdcard/autokit_onboot.sh"

MISSING=0
if [ ! -f "$APK" ]; then
    echo "[!] 缺少: $APK"
    MISSING=1
fi
if [ ! -f "$ONBOOT_SRC" ]; then
    echo "[!] 缺少: $ONBOOT_SRC"
    MISSING=1
fi
if [ $MISSING -eq 1 ]; then
    echo ""
    echo "请先将以下文件复制到车机 /sdcard/ 根目录:"
    echo "  1. AutoKit_2022.11.15.1535.apk"
    echo "  2. autokit_onboot.sh"
    exit 1
fi
echo "[OK] 文件检查通过"

# ---- 部署开机脚本 ----
SCRIPT_DEST="/data/local/tmp/autokit_onboot.sh"
cp "$ONBOOT_SRC" "$SCRIPT_DEST"
chmod 755 "$SCRIPT_DEST"
echo "[OK] 开机脚本已复制到 $SCRIPT_DEST"

# ---- 写入 install-recovery.sh ----
echo "[..] 挂载 /system 为可写..."
mount -o rw,remount /system
if [ $? -ne 0 ]; then
    echo "[!] mount失败，尝试备用方法..."
    mount -o rw,remount /system /system
fi

RECOVERY="/system/etc/install-recovery.sh"

# 备份原文件
if [ -f "$RECOVERY" ]; then
    if [ ! -f "${RECOVERY}.original" ]; then
        cp "$RECOVERY" "${RECOVERY}.original"
        echo "[OK] 已备份原始 install-recovery.sh"
    fi
fi

# 写入新的启动钩子
cat > "$RECOVERY" << 'HOOKEOF'
#!/system/bin/sh
# AutoKit开机自动覆盖安装
# 由deploy_v2.sh自动生成

SCRIPT="/data/local/tmp/autokit_onboot.sh"
if [ -f "$SCRIPT" ]; then
    # 后台执行，不阻塞系统启动
    (sh "$SCRIPT") &
fi

# 如果有原始的recovery脚本，也执行它
ORIGINAL="/system/etc/install-recovery.sh.original"
if [ -f "$ORIGINAL" ]; then
    sh "$ORIGINAL"
fi
HOOKEOF

chmod 755 "$RECOVERY"
chown root:root "$RECOVERY"
echo "[OK] install-recovery.sh 已配置"

mount -o ro,remount /system
echo "[OK] /system 已恢复只读"

# ---- 立即执行一次测试 ----
echo ""
echo "[..] 立即执行覆盖安装测试..."
sh "$SCRIPT_DEST"

echo ""
echo "======================================"
echo " 部署完成！"
echo ""
echo " 效果：每次车机启动后自动执行："
echo "   1. 清除旧的dalvik缓存"
echo "   2. 覆盖安装AutoKit"
echo "   3. 自动打开AutoKit"
echo ""
echo " 重要：请确保 /sdcard/ 根目录下始终保留："
echo "   AutoKit_2022.11.15.1535.apk"
echo "   (不要删除这个文件！)"
echo ""
echo " 查看日志: cat /data/local/tmp/autokit.log"
echo ""
echo " 如需卸载："
echo "   1. mount -o rw,remount /system"
echo "   2. rm /system/etc/install-recovery.sh"
echo "   3. 如有备份: mv /system/etc/install-recovery.sh.original"
echo "      /system/etc/install-recovery.sh"
echo "   4. mount -o ro,remount /system"
echo "   5. rm /data/local/tmp/autokit_onboot.sh"
echo "======================================"
