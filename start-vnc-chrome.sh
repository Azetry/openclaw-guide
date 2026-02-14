#!/bin/bash
# 虛擬桌面 + VNC + Chrome 一鍵啟動腳本
# 用法: ./start-vnc-chrome.sh [網址]
# 預設開啟 pitchbook.com，可傳入其他網址
#
# 注意：此腳本只管理 VNC 用的 Chrome，不會影響 OpenClaw managed browser。
#       兩個 Chrome 使用不同的 user-data-dir，互不干擾。

set -e

URL="${1:-https://pitchbook.com}"
DISPLAY_NUM=99
VNC_PORT=5900
VNC_CHROME_PID_FILE="/tmp/vnc-chrome.pid"

echo "=== 停止既有程序 ==="
pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
pkill -f "x11vnc.*display :$DISPLAY_NUM" 2>/dev/null || true
pkill -f fluxbox 2>/dev/null || true
# 只停止 VNC 的 Chrome（透過 PID 檔），不影響 OpenClaw managed browser
if [ -f "$VNC_CHROME_PID_FILE" ]; then
  VNC_CHROME_PID=$(cat "$VNC_CHROME_PID_FILE")
  if kill -0 "$VNC_CHROME_PID" 2>/dev/null; then
    echo "停止先前的 VNC Chrome (PID: $VNC_CHROME_PID)..."
    kill "$VNC_CHROME_PID" 2>/dev/null || true
  fi
  rm -f "$VNC_CHROME_PID_FILE"
fi
sleep 2

echo "=== 清理 lock 檔 ==="
rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM} 2>/dev/null || true

echo "=== 啟動 Xvfb (虛擬顯示) ==="
nohup Xvfb :$DISPLAY_NUM -screen 0 1920x1080x24 > /tmp/xvfb.log 2>&1 &
sleep 2

export DISPLAY=:$DISPLAY_NUM

echo "=== 啟動 Fluxbox (視窗管理器) ==="
nohup fluxbox > /tmp/fluxbox.log 2>&1 &
sleep 1

echo "=== 啟動 x11vnc ==="
VNC_PASSWD="$HOME/.vnc/passwd"
if [ -f "$VNC_PASSWD" ]; then
  echo "使用已設定的 VNC 密碼 ($VNC_PASSWD)"
  nohup x11vnc -display :$DISPLAY_NUM -forever -shared -rfbport $VNC_PORT -rfbauth "$VNC_PASSWD" -listen 127.0.0.1 > /tmp/x11vnc.log 2>&1 &
else
  echo "未設定 VNC 密碼（建議執行: x11vnc -storepasswd $VNC_PASSWD）"
  nohup x11vnc -display :$DISPLAY_NUM -forever -shared -rfbport $VNC_PORT -nopw -listen 127.0.0.1 > /tmp/x11vnc.log 2>&1 &
fi
sleep 1

echo "=== 啟動 Chrome（VNC 用，獨立於 OpenClaw）==="
nohup google-chrome-stable \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-features=OnDeviceModel \
  "$URL" > /tmp/chrome.log 2>&1 &
# 記錄 PID，供 stop-vnc-chrome.sh 精準停止（不影響 OpenClaw Chrome）
echo $! > "$VNC_CHROME_PID_FILE"
echo "VNC Chrome PID: $(cat "$VNC_CHROME_PID_FILE")"

echo ""
echo "=== 完成 ==="
echo "VNC 已啟動，埠號: $VNC_PORT"
echo ""
echo "連線方式："
echo "  1. SSH 轉發: ssh -L $VNC_PORT:localhost:$VNC_PORT $(whoami)@\$(hostname -I | awk '{print \$1}')"
echo "  2. 用 VNC 客戶端連到 localhost:$VNC_PORT (透過 SSH 轉發後)"
if [ -f "$VNC_PASSWD" ]; then
  echo "  3. VNC 密碼: 已設定（輸入建立密碼時設定的密碼）"
else
  echo "  3. VNC 密碼: 無（建議設定: x11vnc -storepasswd $VNC_PASSWD）"
fi
echo ""
echo "停止腳本: ./stop-vnc-chrome.sh"
echo ""
