# OpenClaw 安裝與設定指南

> **適用對象**：一般上班族、經理主管，建立個人 AI 助理  
> **本指南**：聚焦單 Agent 架構，提供公版模板與引導式設定

這份指南整理了在 Linux VM（無 GUI 桌面）環境下安裝 OpenClaw、設定瀏覽器控制、並透過 Tailscale Serve 公開服務的完整步驟。所有個人設定皆以**公版模板**呈現，引導使用者自行填寫偏好或帶入公版。

---

## 專案結構

```
openclaw-guide/
├── README.md                      # 本文件：安裝與設定總指南
├── docs/                          # 分章節文件
│   ├── 01-architecture.md         # 架構總覽（單 Agent）
│   ├── 02-phase0-environment.md   # 環境準備與安裝
│   ├── 03-phase1-backup.md        # 三層備份體系
│   ├── 04-phase2-bootstrap.md     # Bootstrap 身份建立
│   ├── 05-phase3-core-markdown.md # USER.md、AGENTS.md、TOOLS.md
│   ├── 05b-phase35-version-control.md  # 版控工作流驗證
│   ├── 06-phase4-openclaw-json.md # openclaw.json 核心設定
│   ├── 07-phase11-heartbeat-cron.md    # Heartbeat 與 Cron
│   ├── 08-phase8-workspace-structure.md # Workspace 檔案結構
│   ├── 09-troubleshooting.md      # 常見問題
│   └── 10-quick-reference.md     # 快速參考
├── scripts/                       # 進階備份腳本
│   ├── init-workspace.sh          # 初始化 workspace Git repo
│   ├── setup-config-mirror.sh     # 建立 _config-mirror 脫敏鏡像
│   ├── openclaw-full-backup.sh    # 加密全量備份（第三層）
│   ├── restore-full-backup.sh     # 從加密備份恢復
│   ├── restore-golden-config.sh    # 恢復 Golden Config
│   └── openclaw-git-backup.sh     # Git 備份（可納入 Cron）
├── HEADLESS-LOGIN-GUIDE.md        # 無 GUI 環境下登入需驗證網站的指南
├── BROWSER-CONTROL-GUIDE.md       # 瀏覽器控制模式詳細說明
├── setup-openclaw-browser.sh      # OpenClaw managed browser 設定腳本（推薦）
├── install-openclaw-browser.sh   # 舊版：headless browser 安裝腳本
├── start-vnc-chrome.sh            # 啟動 VNC 虛擬桌面 + Chrome
└── stop-vnc-chrome.sh             # 停止 VNC 虛擬桌面 + Chrome
```

---

## 快速開始（完整流程）

```
Step 1: 環境準備與安裝     → docs/02-phase0-environment.md
Step 2: 三層備份體系       → docs/03-phase1-backup.md
Step 3: Bootstrap 身份建立 → docs/04-phase2-bootstrap.md
Step 4: 核心 Markdown 配置 → docs/05-phase3-core-markdown.md
Step 5: 版控工作流驗證     → docs/05b-phase35-version-control.md
Step 6: openclaw.json 設定 → docs/06-phase4-openclaw-json.md
Step 7: Heartbeat + Cron   → docs/07-phase11-heartbeat-cron.md
Step 8: Workspace 結構     → docs/08-phase8-workspace-structure.md
```

---

## 設計原則

1. **公版優先**：所有設定以模板呈現，使用者需自行填寫偏好（如稱呼、時區、作息等）
2. **引導式**：Onboarding 選擇、Bootstrap 對話、USER.md、HEARTBEAT.md 等皆提供引導範例
3. **工程功能保留**：版控（Git）、三層備份、config mirror、sync-config 等工程面功能完整保留
4. **單 Agent 聚焦**：不涵蓋多 Agent 團隊，適合個人或小團隊使用

---

## 基礎安裝（精簡版）

若你已熟悉 OpenClaw，可先執行：

```bash
# 1. 前置準備
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
sudo apt install -y xvfb x11vnc fluxbox

# 2. 安裝 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon

# 3. Tailscale 權限
sudo tailscale set --operator=$USER
tailscale serve --bg http://localhost:18789

# 4. 設定 VNC（若需 Browser 控制）
cd ~/openclaw-guide
./start-vnc-chrome.sh
./setup-openclaw-browser.sh
```

詳細步驟請參考 [docs/02-phase0-environment.md](docs/02-phase0-environment.md)。

---

## 腳本速查

### 瀏覽器與 VNC

| 腳本 | 用途 | 何時執行 |
|---|---|---|
| `setup-openclaw-browser.sh` | 設定 OpenClaw managed browser | 安裝 OpenClaw 後執行一次 |
| `start-vnc-chrome.sh [URL]` | 啟動 VNC 虛擬桌面 + Chrome | VM 重啟後 |
| `stop-vnc-chrome.sh` | 停止 VNC 環境 | 不需要時 |
| `stop-vnc-chrome.sh --chrome-only` | 只停止 VNC Chrome，保留虛擬桌面 | OpenClaw 仍需要 Xvfb 時 |
| `install-openclaw-browser.sh` | ~~舊版 headless 安裝~~ | 已被 `setup-openclaw-browser.sh` 取代 |

### 備份腳本（scripts/）

| 腳本 | 用途 | 何時執行 |
|---|---|---|
| `scripts/init-workspace.sh` | 初始化 workspace Git repo | Phase 1 第一層 |
| `scripts/setup-config-mirror.sh` | 建立 _config-mirror 脫敏鏡像 | Phase 1 第一層 |
| `scripts/openclaw-full-backup.sh` | 加密全量備份 | 複製到 ~/openclaw-scripts/ 後由 crontab 每日執行 |
| `scripts/restore-full-backup.sh` | 從加密備份恢復 | 災難恢復時 |
| `scripts/restore-golden-config.sh` | 恢復 Golden Config | openclaw.json 改壞時 |
| `scripts/openclaw-git-backup.sh` | Git 備份（含 sync-config） | 可納入 Cron 或由 Agent 觸發 |

> **注意**：`start-vnc-chrome.sh` 和 `stop-vnc-chrome.sh` 只管理 VNC 用的 Chrome，不會影響 OpenClaw 的 managed browser。兩者使用不同的 user-data-dir，互不干擾。

---

## 常用指令

```bash
# Tailscale
tailscale serve status

# OpenClaw
openclaw dashboard --no-open
openclaw doctor
openclaw status
journalctl --user -u openclaw-gateway -f

# 瀏覽器
openclaw browser --browser-profile openclaw status
openclaw browser --browser-profile openclaw start
openclaw browser --browser-profile openclaw stop
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

---

## 參考連結

- [OpenClaw 官方文件](https://docs.openclaw.ai/)
- [OpenClaw Discord 教學](https://docs.openclaw.ai/channels/discord#discord)
- [詳細故障排除](docs/09-troubleshooting.md)
- [快速參考卡](docs/10-quick-reference.md)
