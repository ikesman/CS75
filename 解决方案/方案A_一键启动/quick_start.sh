#!/system/bin/sh
# ============================================
# 【最简方案】AutoKit 桌面快捷启动脚本
# 
# 替代直接点击AutoKit图标
# 每次上车点这个脚本，3秒内自动完成修复+启动
# ============================================

PKG="cn.manstep.phonemirrorBox"

# 静默执行：杀进程 → 清数据 → 启动
am force-stop $PKG >/dev/null 2>&1
pm clear $PKG >/dev/null 2>&1
sleep 1
am start -n $PKG/.CheckActivity >/dev/null 2>&1
