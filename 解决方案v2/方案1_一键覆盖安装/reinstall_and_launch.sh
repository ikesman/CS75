#!/system/bin/sh
# ============================================
# AutoKit 一键覆盖安装启动
# 
# 原理：pm install -r = 覆盖安装（不删除数据）
#       等同于你用RE管理器手动安装，但只要一步
#       覆盖安装会重新触发dexopt，修复损坏的dalvik缓存
#
# 使用前：把 AutoKit_2022.11.15.1535.apk 复制到 /sdcard/
# ============================================

APK="/sdcard/AutoKit_2022.11.15.1535.apk"
PKG="cn.manstep.phonemirrorBox"

if [ ! -f "$APK" ]; then
    echo "找不到APK文件: $APK"
    echo "请先将APK复制到 /sdcard/ 根目录"
    exit 1
fi

# 杀掉残留进程
am force-stop $PKG 2>/dev/null

# 覆盖安装（-r=replace, -d=允许降级）
# 这一步会重新运行dexopt，修复损坏的dalvik缓存
pm install -r -d "$APK"

sleep 2

# 启动应用
am start -n $PKG/.CheckActivity

echo "完成"
