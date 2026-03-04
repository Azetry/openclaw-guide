## 6. Phase 4：openclaw.json 核心設定

> ⚠️ 此檔案在 `~/.openclaw/openclaw.json`，不在 workspace 內。  
> **每次修改前：先備份到 config-backups/**

```bash
# 修改前的標準動作
cp ~/.openclaw/openclaw.json ~/.openclaw/config-backups/openclaw.json.$(date +%Y%m%d-%H%M%S)
```

### 6.1 推薦配置（CLI 方式）

```bash
# ── Tools（Bootstrap 需 coding profile 寫入 SOUL.md / IDENTITY.md）──
openclaw config set tools.profile coding

# ── Heartbeat ──（請依你的作息調整）
openclaw config set agents.defaults.heartbeat.every "30m"
openclaw config set agents.defaults.heartbeat.model "google/gemini-3-flash-preview"  # 或你使用的 model
openclaw config set agents.defaults.heartbeat.activeHours.start "07:00"
openclaw config set agents.defaults.heartbeat.activeHours.end "24:00"
openclaw config set agents.defaults.heartbeat.activeHours.timezone "Asia/Taipei"

# ── Browser（見 6.2，執行腳本後會自動設定）──
openclaw config set browser.enabled true
openclaw config set browser.executablePath "/usr/bin/google-chrome-stable"
openclaw config set browser.noSandbox true
openclaw config set browser.defaultProfile "openclaw"

# ── 安全 ──
# 單人場景可不設，以利自動化；若需審批可啟用：
# openclaw config set security.requireApproval '["shell.execute","fs.write"]' --strict-json
```

### 6.2 Browser + Xvfb 環境建置（一次完成）

> 若需 Browser 控制（抓取網頁、登入網站），搭配 Xvfb 虛擬桌面可避開反 bot 偵測。

```bash
# 1. 安裝 Xvfb 與 VNC 套件
sudo apt install -y xvfb x11vnc fluxbox

# 2. 安裝 Chrome（若尚未安裝）
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb || true
sudo apt --fix-broken install -y
rm -f google-chrome-stable_current_amd64.deb

# 3. 設定 VNC 密碼（建議，首次執行會提示輸入密碼）
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd

# 4. 啟動 Xvfb 虛擬桌面（背景運行）
cd ~/openclaw-guide  # 或你的 openclaw-guide 路徑
./start-vnc-chrome.sh
# 或：Xvfb :99 -screen 0 1024x768x24 &

# 5. 執行 browser 設定（會偵測 Xvfb、設 headless: false、安裝 Playwright）
./setup-openclaw-browser.sh

# 6. 驗證
openclaw browser --browser-profile openclaw status
openclaw browser --browser-profile openclaw open https://google.com
```

> 腳本位於 `openclaw-guide/` 目錄。若跳過 Xvfb 用 headless：`./install-openclaw-browser.sh`。詳見 [BROWSER-CONTROL-GUIDE.md](../BROWSER-CONTROL-GUIDE.md)。

### 6.3 設定完成後

```bash
# 驗證設定
openclaw doctor

# 重啟 Gateway 套用變更
openclaw gateway restart

# ★ 確認正常後，更新 golden config
cp ~/.openclaw/openclaw.json ~/.openclaw/config-backups/openclaw.json.golden

# ★ 若有 _config-mirror，同步脫敏版到 workspace Git
bash ~/.openclaw/workspace/_config-mirror/sync-config.sh
cd ~/.openclaw/workspace
git add _config-mirror/
git commit -m "config: update openclaw.json mirror"
git push
```
