#!/system/bin/sh
# ============================================
# 启用 WiFi ADB 调试
# 执行方式：RE管理器 → Root权限执行
# 执行后电脑即可通过WiFi连接车机ADB
# ============================================

echo "======================================"
echo " 启用 WiFi ADB"
echo "======================================"

# 获取当前WiFi IP
WIFI_IP=$(ifconfig wlan0 2>/dev/null | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1)
if [ -z "$WIFI_IP" ]; then
    WIFI_IP=$(netcfg 2>/dev/null | grep wlan0 | awk '{print $3}' | cut -d/ -f1)
fi

echo ""
echo "WiFi IP: $WIFI_IP"

# 设置ADB TCP端口
setprop service.adb.tcp.port 5555
echo "[1] 已设置 ADB TCP 端口 5555"

# 重启ADB守护进程
stop adbd
start adbd
echo "[2] 已重启 ADB 守护进程"

# 验证
PORT=$(getprop service.adb.tcp.port)
echo ""
echo "======================================"
echo " ADB TCP 端口: $PORT"
echo " 车机IP: $WIFI_IP"
echo ""
echo " 电脑上执行:"
echo "   adb connect $WIFI_IP:5555"
echo "======================================"
