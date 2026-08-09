#!/system/bin/sh
# ============================================
# 手动一键修复（不想等开机自动的时候用）
# 等同于RE管理器里重新安装一遍APK
# ============================================

APK="/sdcard/AutoKit_2022.11.15.1535.apk"
PKG="cn.manstep.phonemirrorBox"

if [ ! -f "$APK" ]; then
    echo "APK不存在: $APK"
    exit 1
fi

am force-stop $PKG 2>/dev/null
rm -f /data/dalvik-cache/*phonemirrorBox* 2>/dev/null
pm install -r -d "$APK"
sleep 2
am start -n $PKG/.CheckActivity
echo "完成"
