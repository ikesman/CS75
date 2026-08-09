#!/system/bin/sh
# ============================================
# v4 修复卸载脚本
# 恢复所有v4修改
# 执行方式：RE管理器 → Root权限执行
# ============================================

echo "======================================"
echo " 卸载 v4 修复"
echo "======================================"

mount -o rw,remount /system 2>/dev/null

# 恢复 install-recovery.sh
if [ -f /system/etc/install-recovery.sh.bak_v4 ]; then
    mv /system/etc/install-recovery.sh.bak_v4 /system/etc/install-recovery.sh
    echo "[OK] install-recovery.sh 已恢复"
else
    rm -f /system/etc/install-recovery.sh
    echo "[OK] install-recovery.sh 已删除"
fi

# 删除开机脚本
rm -f /system/bin/autokit_onboot.sh
echo "[OK] 开机脚本已删除"

# 恢复白名单
if [ -f /system/usr/bootwhitelist.txt.bak_v4 ]; then
    mv /system/usr/bootwhitelist.txt.bak_v4 /system/usr/bootwhitelist.txt
    echo "[OK] 白名单已恢复"
fi

# 恢复黑名单
if [ -f /system/usr/bootblacklist.txt.bak_v4 ]; then
    mv /system/usr/bootblacklist.txt.bak_v4 /system/usr/bootblacklist.txt
    echo "[OK] 黑名单已恢复"
fi

# 删除系统APK (可选)
# rm -f /system/priv-app/AutoKit.apk
echo "[注意] /system/priv-app/AutoKit.apk 已保留"
echo "  如需删除: rm /system/priv-app/AutoKit.apk"

mount -o ro,remount /system 2>/dev/null

echo ""
echo "======================================"
echo " 卸载完成，请重启车机"
echo "======================================"
