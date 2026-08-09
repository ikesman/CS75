#!/system/bin/sh
# ============================================
# Phase 1: 白名单 + 系统应用安装
#
# 关键改进：将AutoKit加入系统启动白名单
# /system/usr/bootwhitelist.txt
#
# 之前方案B仅安装为系统应用但未修改白名单，
# 白名单控制APP的启动保护和缓存管理策略。
#
# 执行方式：RE管理器 → Root权限执行
# ============================================

echo "======================================"
echo " Phase 1: 白名单 + 系统应用安装"
echo "======================================"
echo ""

PKG="cn.manstep.phonemirrorBox"
APK="/sdcard/AutoKit_2022.11.15.1535.apk"
TARGET="/system/priv-app/AutoKit.apk"
WHITELIST="/system/usr/bootwhitelist.txt"

# ---- 检查APK ----
if [ ! -f "$APK" ]; then
    echo "[!] 错误：请先将 AutoKit_2022.11.15.1535.apk 复制到 /sdcard/"
    exit 1
fi
echo "[OK] APK文件存在"

# ---- Step 1: 停止并卸载用户版 ----
echo ""
echo "[1/7] 停止并卸载用户版AutoKit..."
am force-stop $PKG 2>/dev/null
pm uninstall $PKG 2>/dev/null
echo "  已卸载用户版（如果存在）"

# ---- Step 2: 挂载系统分区 ----
echo "[2/7] 挂载 /system 为可写..."
mount -o rw,remount /system
if [ $? -ne 0 ]; then
    mount -o rw,remount /system /system
    if [ $? -ne 0 ]; then
        echo "[!] 错误：无法挂载/system，请确认Root权限"
        exit 1
    fi
fi
echo "  /system 已挂载为可写"

# ---- Step 3: 备份白名单 ----
echo "[3/7] 备份白名单..."
if [ -f "$WHITELIST" ]; then
    if [ ! -f "${WHITELIST}.bak" ]; then
        cp "$WHITELIST" "${WHITELIST}.bak"
        echo "  已备份到 ${WHITELIST}.bak"
    else
        echo "  备份已存在，跳过"
    fi
else
    echo "  白名单文件不存在，将创建"
fi

# ---- Step 4: 添加白名单（核心步骤！）----
echo "[4/7] 添加AutoKit到启动白名单..."
if grep -q "$PKG" "$WHITELIST" 2>/dev/null; then
    echo "  已在白名单中，跳过"
else
    echo "$PKG" >> "$WHITELIST"
    echo "  已添加: $PKG"
fi

echo "  当前白名单内容："
cat "$WHITELIST" | while read line; do
    echo "    - $line"
done

# ---- Step 5: 安装为系统应用 ----
echo "[5/7] 复制APK到系统目录..."
cp "$APK" "$TARGET"
if [ $? -ne 0 ]; then
    echo "[!] 错误：复制失败"
    mount -o ro,remount /system
    exit 1
fi
chmod 644 "$TARGET"
chown root:root "$TARGET"
echo "  已安装到 $TARGET"

# ---- Step 6: 彻底清理缓存和数据 ----
echo "[6/7] 清理dalvik缓存和旧数据..."
rm -f /data/dalvik-cache/*phonemirror* 2>/dev/null
rm -f /data/dalvik-cache/*phonemirrorBox* 2>/dev/null
rm -f /data/dalvik-cache/*AutoKit* 2>/dev/null
rm -rf /data/data/$PKG 2>/dev/null
echo "  缓存和数据已清理"

# ---- Step 7: 恢复只读 ----
echo "[7/7] 恢复/system为只读..."
mount -o ro,remount /system

echo ""
echo "======================================"
echo " 部署完成！"
echo ""
echo " 请执行以下验证："
echo "   1. 完全断电重启（断电瓶30秒以上）"
echo "   2. 重启后手动打开AutoKit"
echo "   3. 再次断电重启，检查是否仍可打开"
echo "   4. 连续测试3次冷启动"
echo ""
echo " 如需恢复原状，执行 phase1_uninstall.sh"
echo "======================================"
