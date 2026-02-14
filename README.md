# OpenClaw 安裝與設定指南

這份指南整理了在 Linux VM（無 GUI 桌面）環境下安裝 OpenClaw、設定瀏覽器控制、並透過 Tailscale Serve 公開服務的完整步驟。

## 專案結構

```
openclaw-guide/
├── README.md                      # 本文件：安裝與設定總指南
├── HEADLESS-LOGIN-GUIDE.md        # 無 GUI 環境下登入需驗證網站的指南
├── BROWSER-CONTROL-GUIDE.md       # 瀏覽器控制模式詳細說明
├── setup-openclaw-browser.sh      # OpenClaw managed browser 設定腳本（推薦）
├── install-openclaw-browser.sh    # 舊版：headless browser 安裝腳本（已被 setup 取代）
├── start-vnc-chrome.sh            # 啟動 VNC 虛擬桌面 + Chrome（手動瀏覽用）
└── stop-vnc-chrome.sh             # 停止 VNC 虛擬桌面 + Chrome
```

---

## 快速開始（完整流程）

```
Step 1: 安裝 OpenClaw          → 第 1~2 節
Step 2: 設定 Tailscale Serve   → 第 3~5 節
Step 3: 安裝 VNC 虛擬桌面      → 第 6 節
Step 4: 設定瀏覽器控制          → 第 7 節 ★ 重要
Step 5: 裝置配對               → 第 8~9 節
```

---

## 1. 前置準備

確保已安裝 Tailscale 並登入：
```bash
tailscale up
```

安裝 VNC 虛擬桌面所需套件（若尚未安裝）：
```bash
sudo apt update
sudo apt install -y xvfb x11vnc fluxbox
```

## 2. 安裝 OpenClaw

執行官方安裝指令：
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

安裝完成後，依照終端機提示進行初始化設定：
1. 選擇 **Local gateway**。
2. 設定 **Workspace directory**（預設即可）。
3. 選擇 **Model/auth provider**（如 Google Gemini、OpenAI）。
4. 完成瀏覽器驗證流程。
5. 記下預設 Port（通常為 **18789**）。
6. **建議**：當被問及是否安裝 Gateway Service 時，選擇 `Yes`，這樣 OpenClaw 就會作為 systemd 服務在背景自動執行，即使關閉終端機也不會中斷。

## 3. 設定 Tailscale 權限（關鍵步驟）

為了讓目前使用者可以直接操作 Tailscale Serve 而不需每次使用 sudo：

```bash
sudo tailscale set --operator=$USER
```

## 4. 啟動 Tailscale Serve

將 OpenClaw 的本地服務（Port 18789）透過 Tailscale 安全地分享出去：

```bash
tailscale serve --bg http://localhost:18789
```

> 注意：如果是第一次使用 Serve 功能，終端機可能會顯示一個網址，要求您先至 Tailscale 管理後台啟用 HTTPS 功能。

## 5. 取得 Gateway Token 並連接 Dashboard

1. **取得 Token 與連接網址**：
   ```bash
   openclaw dashboard --no-open
   ```
   您會看到類似以下的輸出：
   ```
   Dashboard link (with token):
   http://127.0.0.1:18789/#token=acaa78d6...
   ```

2. **組合正確的連線網址**：
   將 `#token=...` 附加到 Tailscale 網址後方：
   ```
   https://<您的Tailscale網址>.ts.net/#token=<您的Token>
   ```

3. **在瀏覽器開啟該網址**。

## 6. 安裝 VNC 虛擬桌面

在無 GUI 的 VM 上，需要虛擬桌面才能讓 OpenClaw 控制瀏覽器（非 headless 模式，能避開反 bot 偵測）。

### 6.1 設定 VNC 密碼（建議）

```bash
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd
```

### 6.2 啟動虛擬桌面

```bash
cd ~/openclaw-guide
./start-vnc-chrome.sh
```

這會啟動：
- **Xvfb** — 虛擬螢幕（`:99`，1920x1080）
- **Fluxbox** — 輕量視窗管理器
- **x11vnc** — VNC 伺服器（port 5900，僅限 localhost）
- **Chrome** — 一般瀏覽用（獨立於 OpenClaw）

### 6.3 VNC 連線

```bash
# 在本地電腦執行 SSH 轉發
ssh -L 5900:localhost:5900 ubuntu@<VM-IP>
# 然後用 VNC 客戶端連到 localhost:5900
```

## 7. 設定 OpenClaw 瀏覽器控制（★ 重要）

這是讓 OpenClaw 能穩定控制瀏覽器的關鍵步驟。

### 為什麼不用 Chrome Extension Relay？

OpenClaw 有兩種瀏覽器控制方式：

| | Managed Browser（推薦） | Chrome Extension Relay |
|---|---|---|
| 穩定性 | **高** — CDP 直連 | 低 — 靠 extension 中繼 |
| 需要手動操作 | 否 | 是（需點擊 extension icon） |
| 連線掉線問題 | 極少 | 常見 |
| Playwright 支援 | 完整 | 部分 |

**結論：使用 Managed Browser（`openclaw` profile），透過 CDP 直接控制。**

### 7.1 執行設定腳本

確保虛擬桌面已啟動（第 6 節），然後執行：

```bash
cd ~/openclaw-guide
./setup-openclaw-browser.sh
```

此腳本會自動完成：
1. 安裝 Playwright + 系統依賴
2. 設定 `browser.headless=false`（在虛擬桌面顯示，可透過 VNC 查看）
3. 在 Gateway systemd service 加入 `DISPLAY=:99`
4. 重啟 Gateway
5. 啟動 managed browser 並驗證

### 7.2 登入需要驗證的網站

```bash
# 用 OpenClaw 開啟目標網站
openclaw browser --browser-profile openclaw open https://需要登入的網站.com

# 透過 VNC 手動完成 Cloudflare 驗證 / 登入
# 登入後 OpenClaw 就能控制該頁面
```

> 詳細指南請參考 [HEADLESS-LOGIN-GUIDE.md](./HEADLESS-LOGIN-GUIDE.md)

### 7.3 常用瀏覽器指令

```bash
openclaw browser --browser-profile openclaw status     # 查看狀態
openclaw browser --browser-profile openclaw start      # 啟動瀏覽器
openclaw browser --browser-profile openclaw stop       # 停止瀏覽器
openclaw browser --browser-profile openclaw tabs       # 列出分頁
openclaw browser --browser-profile openclaw open URL   # 開啟網址
openclaw browser --browser-profile openclaw snapshot   # 擷取頁面快照
openclaw browser --browser-profile openclaw screenshot # 截圖
```

> 瀏覽器控制的完整說明請參考 [BROWSER-CONTROL-GUIDE.md](./BROWSER-CONTROL-GUIDE.md)

## 8. 裝置配對與授權（Device Pairing）

首次開啟含有 Token 的 Dashboard 網址時，可能會顯示 "Pairing Required"：

1. **列出等待中的請求**：
   ```bash
   openclaw devices list
   ```

2. **批准請求**：
   ```bash
   openclaw devices approve <完整RequestID>
   ```

批准成功後，重新整理瀏覽器頁面即可進入 Dashboard。

## 9. Telegram 帳號配對

如果設定了 Telegram Bot：

1. **列出配對請求**：
   ```bash
   openclaw pairing list telegram
   ```

2. **批准請求**（使用 `Code` 欄位，不要用 `telegramUserId`）：
   ```bash
   openclaw pairing approve telegram <Code>
   ```

## 10. 驗證與存取

```bash
tailscale serve status
```

透過 Tailscale 網址（記得加上 Token）即可從任何連線到同一 Tailnet 的裝置存取 OpenClaw。

---

## 腳本速查

| 腳本 | 用途 | 何時執行 |
|---|---|---|
| `setup-openclaw-browser.sh` | 設定 OpenClaw managed browser | 安裝 OpenClaw 後執行一次 |
| `start-vnc-chrome.sh [URL]` | 啟動 VNC 虛擬桌面 + Chrome | VM 重啟後 |
| `stop-vnc-chrome.sh` | 停止 VNC 環境 | 不需要時 |
| `stop-vnc-chrome.sh --chrome-only` | 只停止 VNC Chrome，保留虛擬桌面 | OpenClaw 仍需要 Xvfb 時 |
| `install-openclaw-browser.sh` | ~~舊版 headless 安裝~~ | 已被 `setup-openclaw-browser.sh` 取代 |

> **注意**：`start-vnc-chrome.sh` 和 `stop-vnc-chrome.sh` 只管理 VNC 用的 Chrome，不會影響 OpenClaw 的 managed browser。兩者使用不同的 user-data-dir，互不干擾。

---

## 常用指令

```bash
# Tailscale
tailscale serve status                              # 查看 Serve 狀態
tailscale serve --https=443 off                     # 停止分享

# OpenClaw
openclaw dashboard --no-open                        # 取得 Dashboard Token
journalctl --user -u openclaw-gateway -f            # 查看 Gateway 日誌
ss -tuln | grep 18789                               # 確認 Port 是否聆聽中

# 瀏覽器
openclaw browser profiles                           # 列出所有 browser profiles
openclaw browser --browser-profile openclaw status  # Managed browser 狀態
openclaw browser --browser-profile openclaw start   # 啟動 managed browser
openclaw browser --browser-profile openclaw stop    # 停止 managed browser
```

---

## 架構概覽

```
┌─────────────────────────────────────────────────┐
│  Xvfb :99（虛擬桌面 1920x1080）                  │
│                                                   │
│  ┌─────────────────┐   ┌───────────────────────┐ │
│  │ VNC Chrome       │   │ OpenClaw Chrome       │ │
│  │ (手動瀏覽用)     │   │ (managed browser)     │ │
│  │                   │   │                       │ │
│  │ user-data:       │   │ user-data:            │ │
│  │ ~/.config/       │   │ ~/.openclaw/browser/  │ │
│  │  google-chrome/  │   │  openclaw/user-data   │ │
│  │                   │   │                       │ │
│  │ PID: /tmp/       │   │ CDP port: 18800       │ │
│  │  vnc-chrome.pid  │   │ 由 OpenClaw 管理       │ │
│  └─────────────────┘   └───────────────────────┘ │
│                                                   │
│  Fluxbox（視窗管理器）                             │
├─────────────────────────────────────────────────┤
│  x11vnc（VNC 伺服器 port 5900）                   │
├─────────────────────────────────────────────────┤
│  OpenClaw Gateway（port 18789, systemd service） │
│  ├── DISPLAY=:99                                  │
│  └── Tailscale Serve → HTTPS                     │
└─────────────────────────────────────────────────┘
```
