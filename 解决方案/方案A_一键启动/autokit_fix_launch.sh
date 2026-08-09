#!/system/bin/sh
# ============================================
# AutoKit 一键修复启动脚本
# 用途：解决Quick Boot唤醒后闪退问题
# 使用：通过RE管理器执行，或放到桌面快捷方式
# ============================================

PACKAGE="cn.manstep.phonemirrorBox"
ACTIVITY="cn.manstep.phonemirrorBox/.CheckActivity"

# 1. 强制停止残留进程
am force-stop $PACKAGE 2>/dev/null

# 2. 等待进程完全退出
sleep 1

# 3. 清除应用数据（等同于"清除数据"）
pm clear $PACKAGE

# 4. 等待清理完成
sleep 1

# 5. 重新启动应用
am start -n $ACTIVITY

echo "AutoKit 已重新启动"
