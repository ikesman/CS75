@echo off
chcp 65001 >nul
REM ============================================
REM AutoKit 一键远程修复（Windows版）
REM 通过WiFi ADB覆盖安装并启动
REM
REM 用法：双击运行，或拖放到命令行
REM 前提：电脑装有adb，和车机在同一WiFi
REM ============================================

set CAR_IP=10.0.0.2
set APK_FILE=%~dp0AutoKit_2022.11.15.1535.apk

echo ==============================
echo  AutoKit WiFi ADB 远程修复
echo ==============================
echo.

if not exist "%APK_FILE%" (
    echo [错误] 请将 AutoKit_2022.11.15.1535.apk 放到本脚本同目录
    pause
    exit /b 1
)

echo 车机IP: %CAR_IP%
echo 如果IP不对，请编辑此脚本修改 CAR_IP
echo.

echo [1/3] 连接车机...
adb connect %CAR_IP%:5555
if errorlevel 1 (
    echo 连接失败！请确认：
    echo   - 电脑和车机在同一网络
    echo   - 车机已开机
    echo   - 车机IP地址正确（build.prop中为10.0.0.2）
    pause
    exit /b 1
)

echo.
echo [2/3] 覆盖安装AutoKit（约10-30秒）...
adb -s %CAR_IP%:5555 install -r -d "%APK_FILE%"

echo.
echo [3/3] 启动AutoKit...
adb -s %CAR_IP%:5555 shell am start -n cn.manstep.phonemirrorBox/.CheckActivity

echo.
echo ==============================
echo  完成！AutoKit应该已经打开了
echo ==============================
pause
