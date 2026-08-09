#!/system/bin/sh
# ============================================
# AutoKit 安装为系统应用
# 用途：将AutoKit装入/system/priv-app，获得系统级权限
#       系统应用崩溃后会被ActivityManager自动重启
#       且DEX优化更稳定，可能根治闪退问题
# 
# 前提：需要Root权限
# 使用：通过RE管理器以Root模式执行
# ============================================

APK_SOURCE="/sdcard/AutoKit_2022.11.15.1535.apk"
PACKAGE="cn.manstep.phonemirrorBox"
TARGET="/system/priv-app/AutoKit.apk"

echo "=============================="
echo " AutoKit 系统应用安装工具"
echo "=============================="

# 检查APK文件是否存在
if [ ! -f "$APK_SOURCE" ]; then
    echo "错误：请先将 AutoKit_2022.11.15.1535.apk 复制到 /sdcard/ 根目录"
    echo "当前查找路径: $APK_SOURCE"
    exit 1
fi

echo "[1/7] 卸载用户版AutoKit..."
pm uninstall $PACKAGE 2>/dev/null
am force-stop $PACKAGE 2>/dev/null

echo "[2/7] 挂载system为可写..."
mount -o rw,remount /system
if [ $? -ne 0 ]; then
    echo "错误：无法挂载/system为可写，请确认有Root权限"
    exit 1
fi

echo "[3/7] 复制APK到系统目录..."
cp "$APK_SOURCE" "$TARGET"
if [ $? -ne 0 ]; then
    echo "错误：复制失败"
    mount -o ro,remount /system
    exit 1
fi

echo "[4/7] 设置文件权限..."
chmod 644 "$TARGET"
chown root:root "$TARGET"

echo "[5/7] 清除dalvik缓存..."
CACHE_FILE=$(echo "$TARGET" | sed 's/\//@/g')
rm -f /data/dalvik-cache/system@priv-app@AutoKit.apk@classes.dex 2>/dev/null

echo "[6/7] 重新挂载为只读..."
mount -o ro,remount /system

echo "[7/7] 完成！需要重启车机生效"
echo ""
echo "请重启车机（完全关机再开机，非Quick Boot）"
echo "方法：长按电源键 或 断开电瓶后重新连接"
echo ""
echo "重启后系统会自动优化APK，AutoKit将作为系统应用运行"
echo "=============================="
