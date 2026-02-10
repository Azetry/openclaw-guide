#!/bin/bash
set -e

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Error: Please do not run this script as root (do not use sudo)."
    echo "The script will use sudo internally where needed."
    exit 1
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "Error: npm command not found."
    echo "Please ensure Node.js and npm are installed and in your PATH."
    exit 1
fi

echo "=== 1. 安裝 Google Chrome ==="
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb || true
sudo apt --fix-broken install -y
rm google-chrome-stable_current_amd64.deb
echo "Chrome version: $(google-chrome-stable --version)"

echo "=== 2. 安裝 Playwright（完整版，非 playwright-core）==="
# Use existing .openclaw directory or fallback to home
TARGET_DIR="$HOME/.openclaw"
if [ ! -d "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME"
fi
echo "Installing playwright in: $TARGET_DIR"
cd "$TARGET_DIR"

# Install playwright locally
npm install playwright

echo "=== 3. 安裝 Playwright 系統依賴 ==="
# Install system deps (this might ask for sudo password, but we have passwordless sudo)
npx playwright install-deps chromium

echo "=== 4. 只下載 Chromium（省空間）==="
npx playwright install chromium

echo "=== 5. 配置 OpenClaw ==="
if command -v openclaw &> /dev/null; then
    openclaw config set browser.enabled true
    openclaw config set browser.executablePath "/usr/bin/google-chrome-stable"
    openclaw config set browser.headless true
    openclaw config set browser.noSandbox true
    openclaw config set browser.defaultProfile "openclaw"
    
    echo "=== 6. 重啟 Gateway ==="
    openclaw gateway restart
    
    echo "=== 7. 驗證 ==="
    sleep 3
    openclaw browser --browser-profile openclaw status
    # Wait for gateway to be ready
    sleep 5
    openclaw browser --browser-profile openclaw start || true
    
    echo "Opening example.com..."
    openclaw browser --browser-profile openclaw open https://google.com || true
    
    echo "等待頁面載入..."
    sleep 5
    openclaw browser --browser-profile openclaw snapshot --format aria --limit 50 || true
    
    echo "=== 完成！==="
    echo "如果 snapshot 正常顯示，代表安裝成功。"
    echo "測試 AI snapshot（需要 Playwright）："
    echo "  openclaw browser snapshot"
else
    echo "Warning: openclaw command not found. Skipping configuration verification."
    echo "Please configure OpenClaw manually or ensure it is in your PATH."
fi
