#!/system/bin/sh
# ============================================
# AutoKit 唤醒守护脚本
# 用途：后台持续监控，Quick Boot唤醒后自动修复并启动AutoKit
# 
# 原理：检测screen_on事件或WiFi状态变化，
#       发现异常时自动清除数据并重启APP
# 
# 使用：开机后执行一次即可后台运行
# ============================================

PACKAGE="cn.manstep.phonemirrorBox"
ACTIVITY="cn.manstep.phonemirrorBox/.CheckActivity"
LOG="/data/local/tmp/autokit_guard.log"
WATCHDOG_INTERVAL=15

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> $LOG
    echo "$1"
}

fix_and_launch() {
    log_msg "执行修复启动..."
    am force-stop $PACKAGE 2>/dev/null
    sleep 1
    pm clear $PACKAGE 2>/dev/null
    sleep 1
    am start -n $ACTIVITY 2>/dev/null
    log_msg "AutoKit 已重新启动"
}

log_msg "AutoKit守护进程启动"

# 记录上次已知的screen状态
LAST_SCREEN_STATE=""
LAUNCH_COUNT=0

while true; do
    # 检查screen状态
    SCREEN_STATE=$(dumpsys power 2>/dev/null | grep "mScreenOn=" | head -1)
    
    if [ -z "$SCREEN_STATE" ]; then
        # 备用方案：检查display状态
        SCREEN_STATE=$(dumpsys display 2>/dev/null | grep "mScreenState" | head -1)
    fi
    
    # 检测从灭屏到亮屏的转换（Quick Boot唤醒）
    if echo "$SCREEN_STATE" | grep -q "true\|ON"; then
        if [ "$LAST_SCREEN_STATE" = "OFF" ]; then
            log_msg "检测到屏幕唤醒（可能是Quick Boot恢复）"
            sleep 3  # 等待系统完全恢复
            
            # 检查AutoKit是否正常运行
            RUNNING=$(ps 2>/dev/null | grep "$PACKAGE" | grep -v grep)
            if [ -z "$RUNNING" ]; then
                log_msg "AutoKit未运行，执行修复启动"
                fix_and_launch
                LAUNCH_COUNT=$((LAUNCH_COUNT + 1))
            else
                # 进程存在但可能是僵尸状态，尝试与之交互
                # 通过检查窗口是否存在来判断
                WINDOW=$(dumpsys window windows 2>/dev/null | grep "$PACKAGE")
                if [ -z "$WINDOW" ]; then
                    log_msg "AutoKit进程存在但无窗口，修复重启"
                    fix_and_launch
                    LAUNCH_COUNT=$((LAUNCH_COUNT + 1))
                fi
            fi
        fi
        LAST_SCREEN_STATE="ON"
    else
        LAST_SCREEN_STATE="OFF"
    fi
    
    # 每次循环也检查：如果AutoKit已崩溃（无进程），自动重启
    if [ "$LAST_SCREEN_STATE" = "ON" ]; then
        RUNNING=$(ps 2>/dev/null | grep "$PACKAGE" | grep -v grep)
        if [ -z "$RUNNING" ] && [ $LAUNCH_COUNT -lt 3 ]; then
            log_msg "检测到AutoKit已退出/崩溃，重新启动"
            fix_and_launch
            LAUNCH_COUNT=$((LAUNCH_COUNT + 1))
        fi
    fi
    
    sleep $WATCHDOG_INTERVAL
done
