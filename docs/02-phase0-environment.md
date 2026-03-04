## 2. Phase 0：環境準備與安裝

### 2.1 建議 VM / 機器規格

| 項目 | 建議規格 |
|------|------|
| CPU | 4 core 以上 |
| RAM | 8 GB 以上 |
| Storage | 32 GB 以上 |
| OS | Ubuntu (headless) 或 Linux 伺服器 |

> 輕度使用可更低規格；若需 Browser 控制、多 Cron，建議 8 core / 16GB。

### 2.2 Dependencies 安裝

```bash
# Python（透過 pyenv 或系統套件）
# pyenv install 3.11.9 && pyenv global 3.11.9
# 或：sudo apt install python3 python3-pip

# Node.js（透過 nvm 或系統套件）
# nvm install 24 && nvm use 24
# 或：sudo apt install nodejs npm

# VNC 虛擬桌面（若需 Browser 控制 + 登入網站）
sudo apt install -y xvfb x11vnc fluxbox

# 確認
node -v && npm -v
git --version
```

### 2.3 Discord Bot 前置設定（若使用 Discord）

> 參考：[OpenClaw Discord 官方教學](https://docs.openclaw.ai/channels/discord#discord)

**Discord Developer Portal 操作**：

1. **Bot Page → Privileged Gateway Intents**：
   - ☑ Message Content Intent
   - ☑ Server Members Intent

2. **Bot Page → Reset Token**（複製保存）

3. **OAuth2 Page → 產生邀請連結**：
   - Scopes：`bot`、`applications.commands`
   - Bot Permissions：View Channels、Send Messages、Read Message History、Embed Links、Attach Files

4. **用邀請連結把 Bot 加入你的 Discord Server**

5. **在 Discord App 中複製**：Server ID、Channel ID、User ID（Onboarding 會用到）

### 2.4 安裝 OpenClaw + Onboarding

```bash
# 官方一鍵安裝
curl -fsSL https://openclaw.ai/install.sh | bash

# 執行 onboarding wizard
openclaw onboard --install-daemon
```

**Onboarding 選擇指引**（請依你的需求填寫）：

| 問題 | 建議選擇 | 說明 |
|------|------|------|
| Install? | Yes | |
| Setup mode | Manual | 手動配置每個步驟，較可控 |
| Gateway type | Local gateway | |
| Workspace path | `~/.openclaw/workspace` | 預設即可 |
| AI Provider | 依你偏好 | Moonshot Kimi、Google Gemini、OpenAI 等 |
| API key source | 依 provider 說明 | 從對應平台取得 |
| Model | 依 provider 建議 | |
| Gateway port | 18789 | 預設 |
| Context mode | Lookback | |
| Auth method | Token | |
| Exposure | Serve (Tailscale) | 若需遠端存取 |
| Chat channels | Yes / No | 依你是否用 Discord/Telegram |
| Channel | Discord Bot / Telegram | 若選 Discord，接上面 Bot 設定 |
| DM access policy | Pairing | 較安全 |
| Configure skills now | No | 之後再裝 |
| Enable hooks | All | |
| Install Gateway service | Yes | systemd 管理，開機自啟 |
| Hatch method | Web UI | 透過 Web UI 完成 Bootstrap |

```bash
# 完成後確認
openclaw doctor
openclaw status
```

### 2.5 Tailscale 遠端存取設定（若需遠端存取）

```bash
# 安裝 Tailscale（若尚未安裝）
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# 讓目前使用者可以直接操作 Tailscale Serve（免 sudo）
sudo tailscale set --operator=$USER

# 將 Gateway（Port 18789）透過 Tailscale 安全暴露
tailscale serve --bg http://localhost:18789
```

### 2.6 修正 Tailscale Origin 問題

> 透過 Tailscale 網址存取 Web UI 時出現 "origin not allowed" 錯誤的修正方式：

```bash
# 將下方網址改為你的 Tailscale 網址（tailscale status 可查）
openclaw config set gateway.controlUi.allowedOrigins \
  '["https://你的機器名稱.tailXXXX.ts.net"]' --strict-json

# 確認
openclaw config get gateway.controlUi.allowedOrigins
```

### 2.7 配對裝置（Pairing）

若 DM policy 選了 Pairing，新裝置需要配對才能跟 Bot 對話：

```bash
# 查看待配對裝置
openclaw devices list

# 批准配對請求
openclaw devices approve [request-id]
```
