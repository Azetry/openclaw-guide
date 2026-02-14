# 無 GUI VM 上登入需驗證的網站指南

在 headless VM 上，某些網站（如有 Cloudflare 防護的網站）需要手動完成人機驗證才能登入。本指南說明如何搭配 VNC 虛擬桌面與 OpenClaw managed browser 來處理這個問題。

---

## 推薦方案：VNC + OpenClaw Managed Browser

**這是最穩定、最實用的方案。**

### 原理

```
你的電腦 → VNC → Xvfb 虛擬桌面 → OpenClaw Chrome（CDP 直連）
                                      ↕
                              OpenClaw Gateway（自動控制）
```

1. VM 上跑 Xvfb 虛擬桌面 + VNC
2. OpenClaw 啟動一個專屬的 managed Chrome（透過 CDP 直連控制）
3. 需要登入時，你透過 VNC 連入，手動完成驗證
4. 登入後，OpenClaw 直接透過 CDP 接手控制頁面

### 為什麼不用 Chrome Extension Relay？

| | Managed Browser（推薦） | Chrome Extension Relay（舊方案） |
|---|---|---|
| 連線穩定性 | **高** — CDP 直連，不掉線 | 低 — extension WebSocket 中繼，常斷線 |
| 需手動操作 | 只需登入時 | 每次都要點 extension icon |
| Playwright 支援 | 完整（snapshot/click/type 等） | 部分 |
| 控制方式 | OpenClaw 管理整個 Chrome 生命週期 | 依賴 extension 轉發 |

---

## 設定步驟

### 1. 安裝必要套件

```bash
sudo apt update
sudo apt install -y xvfb x11vnc fluxbox
```

- **Xvfb**：虛擬螢幕（無實體顯示器也能跑 GUI）
- **x11vnc**：VNC 伺服器
- **fluxbox**：輕量視窗管理器
- **Chrome**：由 `setup-openclaw-browser.sh` 自動安裝（如未安裝）

### 2. 設定 VNC 密碼（建議）

```bash
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd
```

依提示輸入兩次密碼。未設定則以無密碼模式運行（僅限 localhost）。

### 3. 啟動虛擬桌面

```bash
cd ~/openclaw-guide
./start-vnc-chrome.sh
```

### 4. 設定 OpenClaw Managed Browser

```bash
./setup-openclaw-browser.sh
```

此腳本會：
- 安裝 Playwright + 系統依賴
- 設定 OpenClaw browser 為非 headless 模式（在虛擬桌面顯示）
- 在 Gateway systemd service 加入 `DISPLAY=:99`
- 重啟 Gateway 並啟動 managed browser

### 5. VNC 連線方式

**SSH 轉發（推薦，較安全）：**
```bash
# 在你的電腦上執行
ssh -L 5900:localhost:5900 ubuntu@<VM的IP或Tailscale-IP>
# 然後用 VNC 客戶端連到 localhost:5900
```

**直接 Tailscale 連線：**
```bash
# 查 Tailscale IP
tailscale ip -4
# 用 VNC 客戶端連到 <Tailscale-IP>:5900
```

**VNC 客戶端建議：**
- 電腦：TigerVNC、Remmina、RealVNC
- 手機：VNC Viewer（iOS/Android）

---

## 登入流程

### 步驟一：用 OpenClaw 開啟目標網站

```bash
openclaw browser --browser-profile openclaw open https://目標網站.com
```

或透過 OpenClaw agent 對話：
> 「幫我開啟 https://目標網站.com」

### 步驟二：透過 VNC 手動登入

1. 用 VNC 客戶端連線到虛擬桌面
2. 你會看到 OpenClaw 的 Chrome 視窗（橘色 UI 色調）
3. 手動完成 Cloudflare 驗證 / 輸入帳密
4. 確認登入成功

### 步驟三：OpenClaw 接手

登入完成後，OpenClaw 就能自動控制該頁面：

```bash
# 擷取頁面快照（確認已登入）
openclaw browser --browser-profile openclaw snapshot

# 截圖確認
openclaw browser --browser-profile openclaw screenshot
```

或直接透過 agent 對話操作頁面。

---

## 常用指令速查

```bash
# 瀏覽器管理
openclaw browser --browser-profile openclaw status      # 查看狀態
openclaw browser --browser-profile openclaw start       # 啟動
openclaw browser --browser-profile openclaw stop        # 停止
openclaw browser --browser-profile openclaw tabs        # 列出分頁
openclaw browser --browser-profile openclaw open URL    # 開啟網址

# 頁面操作
openclaw browser --browser-profile openclaw snapshot    # AI snapshot（含 ref）
openclaw browser --browser-profile openclaw screenshot  # 截圖
openclaw browser --browser-profile openclaw click <ref> # 點擊元素
openclaw browser --browser-profile openclaw type <ref> "文字"  # 輸入文字

# Cookie / Session 管理
openclaw browser --browser-profile openclaw cookies                      # 查看 cookies
openclaw browser --browser-profile openclaw cookies set <name> <value>   # 設定 cookie
openclaw browser --browser-profile openclaw storage local get            # 查看 localStorage
```

---

## 疑難排解

### Q: OpenClaw browser 顯示 "running: false"

```bash
# 確認 Xvfb 是否運行
pgrep -f "Xvfb :99" || echo "Xvfb 未啟動，請先 ./start-vnc-chrome.sh"

# 確認 Gateway 是否有 DISPLAY 環境變數
grep DISPLAY ~/.config/systemd/user/openclaw-gateway.service

# 手動啟動
openclaw browser --browser-profile openclaw start
```

### Q: snapshot 回傳空白或錯誤

```bash
# 檢查 Playwright 是否已安裝
ls ~/.openclaw/node_modules/playwright

# 如果沒有，重新執行設定腳本
./setup-openclaw-browser.sh
```

### Q: 停止 VNC 後 OpenClaw browser 無法使用

OpenClaw 非 headless 模式依賴 Xvfb 虛擬桌面。停止 VNC 時，請使用 `--chrome-only` 保留虛擬桌面：

```bash
# 只停止 VNC 用的 Chrome，保留 Xvfb（OpenClaw 需要）
./stop-vnc-chrome.sh --chrome-only

# 如果完全停止了，重新啟動
./start-vnc-chrome.sh
openclaw browser --browser-profile openclaw start
```

### Q: 從 Chrome Extension Relay 遷移

如果之前使用 Chrome Extension Relay（`chrome` profile），現在想改用 managed browser：

```bash
# 確認 defaultProfile 已設為 openclaw
openclaw config get browser.defaultProfile
# 應該顯示 "openclaw"

# 如果不是，重新設定
openclaw config set browser.defaultProfile openclaw
```

不需要移除 Chrome extension，它不會影響 managed browser。

---

## 其他方案（備參考）

以下方案在特殊情況下可能有用，但一般建議使用上述推薦方案。

### Docker 預裝環境

使用已整合 Xvfb + VNC + Chrome 的 Docker 映像：

```bash
docker run -d --name vnc-browser \
  -p 5901:5901 \
  -p 6901:6901 \
  -e VNC_PASSWORD=your_password \
  accetto/xubuntu-vnc-novnc-chrome

# noVNC（瀏覽器直接開）: http://<VM-IP>:6901
```

### 2Captcha 付費服務（全自動）

需完全自動化驗證時：
- [2Captcha Cloudflare Turnstile 教學](https://2captcha.com/api-docs/cloudflare-turnstile)
- 約 $3/1000 次 Turnstile

### Cookie 匯入

在有 GUI 的電腦登入後匯出 Cookies，再匯入 VM 上的瀏覽器 session。限制：可能很快失效。
