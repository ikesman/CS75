#!/system/bin/sh
# ============================================
# Phase 1 卸载/恢复脚本
# 将AutoKit从系统应用移除，恢复白名单
# 执行方式：RE管理器 → Root权限执行
# ============================================

echo "======================================"
echo " Phase 1 卸载恢复"
echo "======================================"

PKG="cn.manstep.phonemirrorBox"

echo "[1/4] 停止AutoKit..."
am force-stop $PKG 2>/dev/null

echo "[2/4] 挂载/system为可写..."
mount -o rw,remount /system

echo "[3/4] 删除系统应用..."
rm -f /system/priv-app/AutoKit.apk 2>/dev/null

# 恢复白名单
if [ -f "/system/usr/bootwhitelist.txt.bak" ]; then
    cp /system/usr/bootwhitelist.txt.bak /system/usr/bootwhitelist.txt
    echo "  白名单已恢复到原始状态"
else
    # 手动移除
    sed -i "/$PKG/d" /system/usr/bootwhitelist.txt 2>/dev/null
    echo "  已从白名单移除AutoKit"
fi

echo "[4/4] 清理缓存..."
rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
rm -rf /data/data/$PKG 2>/dev/null

mount -o ro,remount /system

echo ""
echo "======================================"
echo " 已恢复。重启后AutoKit将完全移除。"
echo " 如需重新使用，用RE管理器手动安装APK。"
echo "======================================"
