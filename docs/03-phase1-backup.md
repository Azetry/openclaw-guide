## 3. Phase 1：三層備份體系建立（先建再改）

> **核心原則**：還沒改任何東西之前，先把三層防護建好。

---

### 前置：Git 身份設定

```bash
# ★ 首次使用 Git 必做，否則 commit 會失敗
git config --global user.email "你的信箱@example.com"
git config --global user.name "你的名稱"
```

---

### 3.1 第一層：Git Workspace Repo

#### 方式 A：使用腳本（推薦）

從 `openclaw-guide` 目錄執行：

```bash
cd ~/openclaw-guide  # 或你的 openclaw-guide 路徑

# 1. 初始化 workspace Git + 推到 GitHub
./scripts/init-workspace.sh https://github.com/YourOrg/openclaw-workspace.git
cd ~/.openclaw/workspace && git push -u origin main

# 2. 建立 config 脫敏鏡像
./scripts/setup-config-mirror.sh
bash ~/.openclaw/workspace/_config-mirror/sync-config.sh
cd ~/.openclaw/workspace && git add _config-mirror/ && git commit -m "config: add _config-mirror" && git push
```

#### 方式 B：手動執行

```bash
cd ~/.openclaw/workspace

# 1. 建立 .gitignore
cat > .gitignore << 'EOF'
*.log
.cache/
node_modules/
browser-data/
tmp/
*.key
*.pem
credentials/
secrets/
EOF

# 2. Git 初始化
git init
git add -A
git commit -m "v0.0: baseline - onboard completed"
git branch -M main

# 3. 推到 GitHub（先在 GitHub 建立 private repo，不要勾 Initialize with README）
git remote add origin https://github.com/YourOrg/openclaw-workspace.git
git push -u origin main
git tag -a v0.0-baseline -m "Onboard completed"
git push --tags

# 4. 建立 config 脫敏鏡像（回到 openclaw-guide 目錄執行）
cd ~/openclaw-guide
./scripts/setup-config-mirror.sh
bash ~/.openclaw/workspace/_config-mirror/sync-config.sh
cd ~/.openclaw/workspace && git add _config-mirror/ && git commit -m "config: add _config-mirror" && git push
```

> `_config-mirror/` 用於追蹤 workspace 外的 openclaw.json（脫敏版），之後執行 `sync-config.sh` 即可同步。  
> **注意**：API key 等敏感資訊會脫敏，不會被 sync 到 mirror。

---

### 3.2 第二層：Golden Config

```bash
mkdir -p ~/.openclaw/config-backups
cp ~/.openclaw/openclaw.json ~/.openclaw/config-backups/openclaw.json.golden
```

**改壞時恢復**：

```bash
# 方式一：手動
cp ~/.openclaw/config-backups/openclaw.json.golden ~/.openclaw/openclaw.json
openclaw gateway restart

# 方式二：使用腳本
cd ~/openclaw-guide && ./scripts/restore-golden-config.sh
```

---

### 3.3 第三層：加密全量備份

```bash
mkdir -p ~/openclaw-scripts ~/openclaw-backups

# 1. 複製備份腳本
cp ~/openclaw-guide/scripts/openclaw-full-backup.sh ~/openclaw-scripts/
chmod +x ~/openclaw-scripts/openclaw-full-backup.sh

# 2. 建立加密密碼（⚠️ 存好這個密碼！）
openssl rand -base64 32 > ~/.openclaw-backup-passphrase
chmod 600 ~/.openclaw-backup-passphrase
echo "⚠️ 請把以下密碼存到密碼管理器："
cat ~/.openclaw-backup-passphrase

# 3. 加入系統 crontab（每日凌晨 3 點）
(crontab -l 2>/dev/null; echo "0 3 * * * $HOME/openclaw-scripts/openclaw-full-backup.sh >> $HOME/openclaw-backups/backup.log 2>&1") | crontab -
```

**恢復**：

```bash
cd ~/openclaw-guide
./scripts/restore-full-backup.sh ~/openclaw-backups/openclaw-backup-XXXXXXXX-XXXXXX.tar.gz.gpg
```

---

### 3.4 收尾：打 tag（可選）

三層都建立完成後，為 workspace 打穩定版 tag：

```bash
cd ~/.openclaw/workspace
git tag -a v0.0-backup-complete -m "Onboard + three-tier backup system"
git push --tags
```
