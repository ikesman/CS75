#!/system/bin/sh
# ============================================
# 方案3：利用车机已有的 CS75Logic 广播机制
# 
# 车机系统中 CS75Logic.apk 在ACC ON（上电）时
# 会发送系统广播，我们可以利用这个机制。
#
# 但更简单的方法是：直接利用车机ADB端口5555
# 做一个"开机检测+自动修复"的循环
# ============================================

# 此脚本在电脑/手机上通过WiFi ADB执行（不需要在车机上操作）
# 前提：电脑和车机在同一网络

CAR_IP="$1"
APK_LOCAL="$2"

if [ -z "$CAR_IP" ] || [ -z "$APK_LOCAL" ]; then
    echo "用法: $0 <车机IP> <APK文件路径>"
    echo "例如: $0 192.168.1.100 ./AutoKit_2022.11.15.1535.apk"
    exit 1
fi

echo "连接车机 $CAR_IP:5555..."
adb connect "$CAR_IP:5555"

if [ $? -ne 0 ]; then
    echo "连接失败，请确认："
    echo "  1. 电脑和车机在同一WiFi网络"
    echo "  2. 车机已开机"
    exit 1
fi

echo "覆盖安装AutoKit..."
adb -s "$CAR_IP:5555" install -r -d "$APK_LOCAL"

echo "启动AutoKit..."
adb -s "$CAR_IP:5555" shell am start -n cn.manstep.phonemirrorBox/.CheckActivity

echo "完成！"
