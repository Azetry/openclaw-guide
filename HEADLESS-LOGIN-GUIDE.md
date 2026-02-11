# 無 GUI VM 上登入需驗證的網站（對抗 Cloudflare）實務指南

你在 headless VM 上，無法手動完成 Cloudflare 人機驗證。以下是幾種可行方案，依推薦順序排列。

---

## 方案一：VNC + 虛擬顯示（最推薦）

**原理**：在 VM 上跑一個「虛擬桌面」，用 VNC 從手機/筆電連進去，手動完成驗證後，再由 OpenClaw 接手。

### 1. 安裝必要套件

```bash
sudo apt update
sudo apt install -y xvfb x11vnc fluxbox google-chrome-stable
```

- **Xvfb**：虛擬螢幕（無實體顯示器也能跑 GUI）
- **x11vnc**：VNC 伺服器
- **fluxbox**：輕量視窗管理員
- **Chrome**：你已有，可略過

### 2. 設定 VNC 密碼（建議）

第一次使用前，建議設定 VNC 密碼以保護連線安全：

```bash
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd
```

依提示輸入兩次密碼，密碼會加密儲存。未設定時腳本會以無密碼模式運行（僅限 localhost）。

### 3. 啟動虛擬桌面 + VNC

```bash
# 建立虛擬顯示
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99

# 啟動視窗管理器
fluxbox &

# 啟動 Chrome（非 headless，會顯示在虛擬桌面）
google-chrome-stable --no-sandbox --disable-dev-shm-usage &
sleep 5

# 啟動 VNC 伺服器（僅監聽 localhost）
# 有密碼檔時：x11vnc -display :99 -forever -shared -rfbport 5900 -rfbauth ~/.vnc/passwd -listen 127.0.0.1 &
# 無密碼時：x11vnc -display :99 -forever -shared -rfbport 5900 -nopw -listen 127.0.0.1 &
x11vnc -display :99 -forever -shared -rfbport 5900 -nopw -listen 127.0.0.1 &
```

### 4. 從外部連線到 VNC

你的 VM 有 Tailscale，可用 Tailscale IP 連線：

```bash
# 在 VM 上查 Tailscale IP
tailscale ip -4
```

**在另一台有 GUI 的裝置（筆電、手機）上：**

- **選項 A：SSH 轉發（較安全）**
  ```bash
  ssh -L 5900:localhost:5900 ubuntu@<你的VM的Tailscale-IP>
  ```
  然後用 VNC 客戶端連到 `localhost:5900`

- **選項 B：直接用 Tailscale**
  若 VM 有裝 Tailscale，用 VNC 客戶端連到 `<VM的Tailscale-IP>:5900`

**VNC 客戶端建議：**
- 電腦：TigerVNC、Remmina、RealVNC
- 手機：VNC Viewer (iOS/Android)

**VNC 密碼**：若已執行 `x11vnc -storepasswd ~/.vnc/passwd`，連線時會要求輸入密碼；未設定則可直接連入。

### 5. 手動完成登入後

1. 在 VNC 視窗裡打開目標網站（例如需登入的網站）
2. 手動完成 Cloudflare 驗證
3. 輸入帳密登入
4. 登入成功後，OpenClaw 理論上可以透過同一瀏覽器 session 或 cookie 接手（需視 OpenClaw 實作而定）

---

## 方案二：Docker 預裝環境（最省事）

使用已整合 Xvfb + VNC + Chrome 的 Docker 映像：

```bash
# 拉取並執行
docker run -d --name vnc-browser \
  -p 5901:5901 \
  -p 6901:6901 \
  -e VNC_PASSWORD=your_password \
  accetto/xubuntu-vnc-novnc-chrome

# 連線方式：
# VNC: <VM-IP>:5901
# noVNC (瀏覽器直接開): http://<VM-IP>:6901
```

有 GUI 的裝置用瀏覽器開 `http://<VM-IP>:6901` 即可操作，無需安裝 VNC 客戶端。

---

## 方案三：2Captcha 付費服務（全自動）

若想完全自動化、不手動操作，可付費使用 CAPTCHA 破解服務。

### 流程

1. 用 Puppeteer/Playwright 控制 Chrome
2. 遇到 Cloudflare Turnstile 時，呼叫 2Captcha API
3. 取得 token 後注入頁面，繼續登入流程

### 成本

- 2Captcha：約 $3/1000 次 Turnstile
- 需撰寫整合腳本

### 參考資源

- [2Captcha Cloudflare Turnstile 教學](https://2captcha.com/api-docs/cloudflare-turnstile)
- [Puppeteer + 2Captcha  bypass 範例](https://2captcha.com/blog/bypassing-cloudflare-challenge-with-puppeteer-and-2captcha)

---

## 方案四：undetected-chromedriver（降低偵測率）

可降低被 Cloudflare 偵測為 bot 的機率，但**無法保證**通過人機驗證。

```bash
pip install undetected-chromedriver selenium
```

```python
import undetected_chromedriver as uc

options = uc.ChromeOptions()
options.add_argument('--no-sandbox')
driver = uc.Chrome(options=options)
driver.get('https://example.com')  # 替換成你的目標網址
# 仍有機會被 Cloudflare 擋下
```

---

## 方案五：Cookie 匯入（需有另一台有 GUI 的電腦）

若你有另一台可手動登入的電腦：

1. 在有 GUI 的電腦登入目標網站，完成 Cloudflare 驗證
2. 匯出 Cookies（可用瀏覽器擴充如 EditThisCookie）
3. 將 Cookies 匯入 VM 上的 headless 瀏覽器 session

**限制**：該網站可能有額外檢查（IP、fingerprint），Cookie 可能很快失效。

---

## 總結建議

| 情境 | 建議方案 |
|------|----------|
| 偶爾登入、可接受手動驗證 | **方案一或二**（VNC） |
| 需完全自動化、可付費 | **方案三**（2Captcha） |
| 想先試試看能否自動過 | **方案四**（undetected-chromedriver） |

對 headless VM 而言，**方案一（VNC）** 最實務：你從手機/筆電連進去，手動完成驗證，之後可再研究如何讓 OpenClaw 接手已登入的 session。

---

## 一鍵啟動腳本（方案一）

專案內含 `start-vnc-chrome.sh` 與 `stop-vnc-chrome.sh`。

### 首次使用：設定 VNC 密碼（建議）

```bash
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd
```

依提示輸入兩次密碼。未設定則以無密碼模式運行（僅限 localhost，較不安全）。

### 啟動與停止

```bash
cd /home/ubuntu/openclaw-guide

# 啟動（預設開啟指定網址，可傳入參數指定需登入的網站）
./start-vnc-chrome.sh

# 指定網址
./start-vnc-chrome.sh https://example.com

# 停止
./stop-vnc-chrome.sh
```

### 連線方式

1. 在另一台有 GUI 的裝置執行：`ssh -L 5900:localhost:5900 ubuntu@<VM-IP>`
2. 用 VNC 客戶端連到 `localhost:5900`
3. 若已設定密碼，連線時輸入密碼

腳本會自動偵測 `~/.vnc/passwd`：存在則啟用密碼驗證，不存在則無密碼運行。
