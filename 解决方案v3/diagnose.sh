#!/system/bin/sh
# ============================================
# 诊断脚本：验证 Phase 1 部署状态
# 在部署后、重启前/后均可运行
# 执行方式：RE管理器 → Root权限执行
# ============================================

echo "======================================"
echo " AutoKit Phase 1 部署诊断"
echo "======================================"

PKG="cn.manstep.phonemirrorBox"

echo ""
echo "[1] 白名单检查："
if [ -f /system/usr/bootwhitelist.txt ]; then
    if grep -q "$PKG" /system/usr/bootwhitelist.txt; then
        echo "  ✓ AutoKit在白名单中"
    else
        echo "  ✗ AutoKit不在白名单中！"
    fi
    echo "  白名单内容："
    cat /system/usr/bootwhitelist.txt | while read line; do
        echo "    $line"
    done
else
    echo "  ✗ 白名单文件不存在！"
fi

echo ""
echo "[2] 系统应用检查："
if [ -f /system/priv-app/AutoKit.apk ]; then
    ls -la /system/priv-app/AutoKit.apk
    echo "  ✓ APK存在于priv-app"
else
    echo "  ✗ APK不在priv-app中！"
fi

echo ""
echo "[3] 包管理器状态："
pm list packages -s 2>/dev/null | grep phonemirror
if [ $? -eq 0 ]; then
    echo "  ✓ AutoKit是系统应用"
else
    echo "  ✗ AutoKit不是系统应用（或未安装）"
fi
pm list packages 2>/dev/null | grep phonemirror
if [ $? -eq 0 ]; then
    echo "  ✓ AutoKit已安装"
else
    echo "  ✗ AutoKit未安装"
fi

echo ""
echo "[4] Dalvik缓存："
ls -la /data/dalvik-cache/*AutoKit* 2>/dev/null
ls -la /data/dalvik-cache/*phonemirror* 2>/dev/null
if [ $? -ne 0 ]; then
    echo "  (无缓存文件 - 重启后系统会自动生成)"
fi

echo ""
echo "[5] 应用数据："
if [ -d /data/data/$PKG ]; then
    ls -la /data/data/$PKG/
    echo "  ✓ 数据目录存在"
else
    echo "  (无数据目录 - 首次启动后生成)"
fi

echo ""
echo "[6] 黑名单检查："
if [ -f /system/usr/bootblacklist.txt ]; then
    if grep -q "$PKG" /system/usr/bootblacklist.txt; then
        echo "  ✗ 警告：AutoKit在黑名单中！需要移除！"
    else
        echo "  ✓ AutoKit不在黑名单中"
    fi
fi

echo ""
echo "======================================"
echo " 诊断完成"
echo "======================================"
