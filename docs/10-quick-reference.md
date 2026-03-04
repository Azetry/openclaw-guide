## 10. 快速參考卡

### 一句話流程

```
Discord Bot 設定（可選）→ Tailscale（可選）→ OpenClaw + Onboarding → 
三層備份 → Bootstrap → SOUL.md + IDENTITY.md → USER.md + AGENTS.md + TOOLS.md → 
openclaw.json（含 Browser + Xvfb）→ Phase 3.5 版控驗證 → 
Heartbeat + Cron → Workspace 結構 → 打 stable tag
```

### 改動 SOP

```
Workspace 檔案：
  1. git checkout -b experiment/xxx
  2. 修改 → 測試
  3. OK → merge + tag + push  |  爛了 → checkout main + delete branch

openclaw.json：
  1. cp 到 config-backups/
  2. 修改 → doctor → restart
  3. OK → 更新 golden + sync-config.sh + commit 鏡像
```

### Browser + VNC 速查

```bash
# VNC 虛擬桌面
./start-vnc-chrome.sh                 # 啟動 VNC + Chrome
./stop-vnc-chrome.sh                  # 停止全部
./stop-vnc-chrome.sh --chrome-only    # 只停 Chrome，保留 Xvfb

# OpenClaw Managed Browser
openclaw browser --browser-profile openclaw status
openclaw browser --browser-profile openclaw start
openclaw browser --browser-profile openclaw stop
openclaw browser --browser-profile openclaw open URL
openclaw browser --browser-profile openclaw tabs
openclaw browser --browser-profile openclaw snapshot --format aria --limit 50

# VNC 連線
ssh -L 5900:localhost:5900 user@<VM-IP>
# → VNC 客戶端連 localhost:5900
```

### 緊急回滾

```bash
# Workspace（秒級）
cd ~/.openclaw/workspace && git checkout vX.Y-stable

# Config（秒級）
cp ~/.openclaw/config-backups/openclaw.json.golden ~/.openclaw/openclaw.json
openclaw gateway restart
```
