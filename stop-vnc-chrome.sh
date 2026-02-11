#!/bin/bash
# 停止虛擬桌面 + VNC + Chrome

DISPLAY_NUM=99

echo "=== 停止 VNC 環境 ==="
pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
pkill -f "x11vnc.*display :$DISPLAY_NUM" 2>/dev/null || true
pkill -f fluxbox 2>/dev/null || true
pkill -f "google-chrome-stable" 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

sleep 1
rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM} 2>/dev/null || true

echo "已停止。"
