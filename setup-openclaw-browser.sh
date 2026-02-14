#!/bin/bash
# =============================================================================
# setup-openclaw-browser.sh
# OpenClaw managed browser 設定腳本（搭配 Xvfb 虛擬桌面）
#
# 用途：安裝好 OpenClaw 後，一鍵設定 managed browser（openclaw profile）
#       讓 OpenClaw 透過 CDP 直接控制專屬 Chrome，不需要 Chrome extension relay
#
# 前置條件：
#   1. 已安裝 OpenClaw（openclaw 指令可用）
#   2. 已安裝 Google Chrome（google-chrome-stable）
#   3. 已啟動 Xvfb 虛擬桌面（start-vnc-chrome.sh 或手動啟動）
#   4. 已安裝 npm
#
# 使用方式：
#   chmod +x setup-openclaw-browser.sh
#   ./setup-openclaw-browser.sh
#
# 說明：
#   - 此腳本會設定 OpenClaw 的 "openclaw" profile（managed browser）
#   - 該 Chrome 實例獨立於 start-vnc-chrome.sh 啟動的 Chrome
#   - OpenClaw Chrome 使用自己的 user-data-dir 和 CDP port 18800
#   - 你可以透過 VNC 看到 OpenClaw 控制的瀏覽器畫面
#   - 如需登入網站，透過 VNC 手動登入即可
# =============================================================================

set -e

DISPLAY_NUM=99

# --- 顏色輸出 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 檢查前置條件 ---
echo "=========================================="
echo " OpenClaw Managed Browser 設定"
echo "=========================================="
echo ""

# 不可用 root 執行
if [ "$EUID" -eq 0 ]; then
    error "請不要用 root 執行此腳本（不要 sudo）。"
    exit 1
fi

# 檢查 openclaw
if ! command -v openclaw &> /dev/null; then
    error "找不到 openclaw 指令。請先安裝 OpenClaw。"
    exit 1
fi
info "OpenClaw: $(openclaw --version 2>/dev/null || echo '已安裝')"

# 檢查 Chrome
if ! command -v google-chrome-stable &> /dev/null; then
    warn "找不到 google-chrome-stable，嘗試安裝..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb || true
    sudo apt --fix-broken install -y
    rm -f google-chrome-stable_current_amd64.deb
fi
info "Chrome: $(google-chrome-stable --version 2>/dev/null)"

# 檢查 npm
if ! command -v npm &> /dev/null; then
    error "找不到 npm。請先安裝 Node.js 和 npm。"
    exit 1
fi

# 檢查 Xvfb 是否運行
if ! pgrep -f "Xvfb :$DISPLAY_NUM" > /dev/null 2>&1; then
    warn "Xvfb :$DISPLAY_NUM 尚未啟動。"
    warn "請先執行 ./start-vnc-chrome.sh 啟動虛擬桌面，再執行此腳本。"
    warn "或者腳本會以 headless 模式設定（無法透過 VNC 查看）。"
    echo ""
    read -p "是否以 headless 模式繼續？[y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    USE_HEADLESS=true
else
    USE_HEADLESS=false
    info "Xvfb :$DISPLAY_NUM 運行中 ✓"
fi

# =============================================================================
echo ""
echo "=== 1. 安裝 Playwright ==="
# =============================================================================
TARGET_DIR="$HOME/.openclaw"
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

# 檢查是否已安裝
if [ -d "$TARGET_DIR/node_modules/playwright" ]; then
    info "Playwright 已安裝，跳過。"
else
    info "安裝 Playwright 到 $TARGET_DIR ..."
    cd "$TARGET_DIR"
    npm install playwright
fi

# 安裝系統依賴
info "安裝 Playwright 系統依賴..."
cd "$TARGET_DIR"
npx playwright install-deps chromium 2>/dev/null || true

# 安裝 Chromium（Playwright 用）
info "安裝 Playwright Chromium..."
npx playwright install chromium 2>/dev/null || true

# =============================================================================
echo ""
echo "=== 2. 設定 OpenClaw Browser ==="
# =============================================================================

if [ "$USE_HEADLESS" = true ]; then
    info "設定為 headless 模式"
    openclaw config set browser.headless true
else
    info "設定為非 headless 模式（透過 VNC 可見）"
    openclaw config set browser.headless false
fi

openclaw config set browser.enabled true
openclaw config set browser.executablePath "/usr/bin/google-chrome-stable"
openclaw config set browser.noSandbox true
openclaw config set browser.defaultProfile "openclaw"

info "Browser 設定完成"
openclaw config get browser

# =============================================================================
echo ""
echo "=== 3. 設定 Gateway systemd service（加入 DISPLAY 環境變數）==="
# =============================================================================

SERVICE_FILE="$HOME/.config/systemd/user/openclaw-gateway.service"

if [ ! -f "$SERVICE_FILE" ]; then
    warn "找不到 Gateway systemd service: $SERVICE_FILE"
    warn "如果 Gateway 不是用 systemd 管理的，請手動設定 DISPLAY=:$DISPLAY_NUM"
else
    # 檢查是否已有 DISPLAY 設定
    if grep -q "Environment=DISPLAY=:$DISPLAY_NUM" "$SERVICE_FILE"; then
        info "DISPLAY=:$DISPLAY_NUM 已設定，跳過。"
    else
        info "在 Gateway service 加入 DISPLAY=:$DISPLAY_NUM ..."

        # 在最後一個 Environment= 行之後加入 DISPLAY
        # 使用 sed 在 [Service] 段的 Environment 行後面插入
        if grep -q "Environment=DISPLAY=" "$SERVICE_FILE"; then
            # 已有 DISPLAY 設定但值不同，替換之
            sed -i "s|Environment=DISPLAY=.*|Environment=DISPLAY=:$DISPLAY_NUM|" "$SERVICE_FILE"
            info "已更新 DISPLAY 設定為 :$DISPLAY_NUM"
        else
            # 沒有 DISPLAY 設定，在最後一個 Environment= 行後面加入
            sed -i "/^Environment=OPENCLAW_SERVICE_KIND=/a Environment=DISPLAY=:$DISPLAY_NUM" "$SERVICE_FILE"
            info "已加入 DISPLAY=:$DISPLAY_NUM"
        fi
    fi

    echo ""
    info "Gateway service 設定檔："
    grep "Environment=" "$SERVICE_FILE"
fi

# =============================================================================
echo ""
echo "=== 4. 重啟 Gateway ==="
# =============================================================================

systemctl --user daemon-reload
info "systemd daemon-reload 完成"

systemctl --user restart openclaw-gateway.service
info "Gateway 已重啟"

# 等待 Gateway 就緒
info "等待 Gateway 啟動..."
sleep 5

# 驗證 Gateway 狀態
if systemctl --user is-active --quiet openclaw-gateway.service; then
    info "Gateway 運行中 ✓"
else
    error "Gateway 啟動失敗！"
    systemctl --user status openclaw-gateway.service --no-pager
    exit 1
fi

# =============================================================================
echo ""
echo "=== 5. 啟動 Managed Browser ==="
# =============================================================================

info "啟動 openclaw managed browser..."
sleep 2
openclaw browser --browser-profile openclaw start 2>&1 || true
sleep 3

# 檢查狀態
info "Browser 狀態："
openclaw browser --browser-profile openclaw status

# =============================================================================
echo ""
echo "=== 6. 驗證 ==="
# =============================================================================

info "開啟測試頁面 https://example.com ..."
openclaw browser --browser-profile openclaw open https://example.com 2>&1 || true
sleep 3

info "列出 tabs："
openclaw browser --browser-profile openclaw tabs 2>&1 || true

info "測試 snapshot："
openclaw browser --browser-profile openclaw snapshot --format aria --limit 30 2>&1 || true

# =============================================================================
echo ""
echo "=========================================="
echo " 設定完成！"
echo "=========================================="
echo ""
echo "使用方式："
echo "  openclaw browser --browser-profile openclaw status   # 查看狀態"
echo "  openclaw browser --browser-profile openclaw start    # 啟動瀏覽器"
echo "  openclaw browser --browser-profile openclaw stop     # 停止瀏覽器"
echo "  openclaw browser --browser-profile openclaw tabs     # 列出分頁"
echo "  openclaw browser --browser-profile openclaw open URL # 開啟網址"
echo "  openclaw browser --browser-profile openclaw snapshot # 擷取頁面快照"
echo ""
if [ "$USE_HEADLESS" = false ]; then
    echo "你可以透過 VNC 連線（port 5900）看到 OpenClaw 控制的瀏覽器。"
    echo "瀏覽器 UI 會有橘色色調，表示這是 OpenClaw 管理的實例。"
    echo ""
    echo "如需登入網站："
    echo "  1. 用 openclaw browser open https://需要登入的網站.com"
    echo "  2. 透過 VNC 手動登入"
    echo "  3. 登入後 OpenClaw 就能控制該頁面"
    echo ""
fi
echo "注意：此瀏覽器與 start-vnc-chrome.sh 啟動的 Chrome 是獨立的。"
echo "  - OpenClaw Chrome: user-data 在 ~/.openclaw/browser/openclaw/user-data"
echo "  - VNC Chrome: user-data 在 ~/.config/google-chrome/ (預設)"
echo ""
