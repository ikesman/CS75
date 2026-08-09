#!/system/bin/sh
# ============================================
# AutoKit 开机自动覆盖安装守护
#
# 核心方案：开机后自动执行 pm install -r 覆盖安装APK
# 这完全等同于你手动用RE管理器安装的效果
# 安装完成后自动启动APP
#
# 部署后效果：上车→开机→等15秒→CarPlay自动可用
# ============================================

APK="/sdcard/AutoKit_2022.11.15.1535.apk"
PKG="cn.manstep.phonemirrorBox"
ACTIVITY="cn.manstep.phonemirrorBox/.CheckActivity"
LOG="/data/local/tmp/autokit_boot.log"

log_msg() {
    echo "$(date '+%m-%d %H:%M:%S') $1" >> "$LOG" 2>/dev/null
}

log_msg "===== 守护进程启动 ====="

# 等待系统完全启动（包管理器就绪）
RETRY=0
while [ $RETRY -lt 30 ]; do
    pm path $PKG > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 1
    RETRY=$((RETRY + 1))
done

log_msg "系统就绪，等待$RETRY秒"

if [ ! -f "$APK" ]; then
    log_msg "APK不存在: $APK"
    # 即使APK不在sdcard，也尝试直接启动看看
    am start -n $ACTIVITY 2>/dev/null
    exit 1
fi

# 杀掉可能的残留进程
am force-stop $PKG 2>/dev/null
sleep 1

# 核心操作：覆盖安装，触发dexopt重新优化
log_msg "执行覆盖安装..."
RESULT=$(pm install -r -d "$APK" 2>&1)
log_msg "安装结果: $RESULT"

sleep 2

# 启动APP
log_msg "启动AutoKit..."
am start -n $ACTIVITY 2>/dev/null

log_msg "===== 完成 ====="
