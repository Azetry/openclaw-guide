#!/bin/bash
# 停止虛擬桌面 + VNC + Chrome（僅 VNC 用的 Chrome）
#
# 注意：此腳本不會停止 OpenClaw managed browser。
#       如需停止 OpenClaw 的瀏覽器，請用：
#         openclaw browser --browser-profile openclaw stop
#
# ⚠️  停止 Xvfb 會同時影響 OpenClaw managed browser 的顯示！
#     如果你只想停止 VNC Chrome，請用: ./stop-vnc-chrome.sh --chrome-only

DISPLAY_NUM=99
VNC_CHROME_PID_FILE="/tmp/vnc-chrome.pid"

if [ "$1" = "--chrome-only" ]; then
    echo "=== 只停止 VNC Chrome ==="
    if [ -f "$VNC_CHROME_PID_FILE" ]; then
        VNC_CHROME_PID=$(cat "$VNC_CHROME_PID_FILE")
        if kill -0 "$VNC_CHROME_PID" 2>/dev/null; then
            echo "停止 VNC Chrome (PID: $VNC_CHROME_PID)..."
            kill "$VNC_CHROME_PID" 2>/dev/null || true
        else
            echo "VNC Chrome (PID: $VNC_CHROME_PID) 已不存在。"
        fi
        rm -f "$VNC_CHROME_PID_FILE"
    else
        echo "找不到 VNC Chrome PID 檔。"
    fi
    echo "已完成（Xvfb/VNC/Fluxbox 保持運行）。"
    exit 0
fi

echo "=== 停止 VNC 環境 ==="

# 停止 VNC Chrome（透過 PID 檔，不影響 OpenClaw Chrome）
if [ -f "$VNC_CHROME_PID_FILE" ]; then
    VNC_CHROME_PID=$(cat "$VNC_CHROME_PID_FILE")
    if kill -0 "$VNC_CHROME_PID" 2>/dev/null; then
        echo "停止 VNC Chrome (PID: $VNC_CHROME_PID)..."
        kill "$VNC_CHROME_PID" 2>/dev/null || true
    fi
    rm -f "$VNC_CHROME_PID_FILE"
fi

# 檢查 OpenClaw managed browser 是否運行中
OPENCLAW_BROWSER_RUNNING=false
if command -v openclaw &> /dev/null; then
    if openclaw browser --browser-profile openclaw status 2>/dev/null | grep -q "running: true"; then
        OPENCLAW_BROWSER_RUNNING=true
    fi
fi

if [ "$OPENCLAW_BROWSER_RUNNING" = true ]; then
    echo ""
    echo "⚠️  OpenClaw managed browser 正在運行！"
    echo "   停止 Xvfb 會影響 OpenClaw 的瀏覽器顯示。"
    echo "   如果 OpenClaw browser 設為 headless 模式則不受影響。"
    echo ""
    read -p "確定要停止整個 VNC 環境嗎？[y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消。VNC Chrome 已停止，但 Xvfb/VNC 保持運行。"
        exit 0
    fi
fi

pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
pkill -f "x11vnc.*display :$DISPLAY_NUM" 2>/dev/null || true
pkill -f fluxbox 2>/dev/null || true

sleep 1
rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM} 2>/dev/null || true

echo "已停止。"
if [ "$OPENCLAW_BROWSER_RUNNING" = true ]; then
    echo "提示：OpenClaw managed browser 可能需要重新啟動："
    echo "  openclaw browser --browser-profile openclaw start"
fi
