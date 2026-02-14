# OpenClaw 瀏覽器控制完整指南

OpenClaw 可以透過 CDP（Chrome DevTools Protocol）直接控制 Chrome 瀏覽器，實現自動化的頁面操作。本文件整理了瀏覽器控制的各種模式、完整 CLI 指令和 debug 技巧。

> 官方文件：
> - [Browser 管理](https://docs.openclaw.ai/cli/browser)
> - [Managed Browser](https://docs.openclaw.ai/tools/browser)
> - [登入指南](https://docs.openclaw.ai/tools/browser-login)
> - [Linux 疑難排解](https://docs.openclaw.ai/tools/browser-linux-troubleshooting)

---

## 控制模式比較

OpenClaw 支援三種瀏覽器控制方式：

| 模式 | Profile 名稱 | 說明 | 穩定性 | 適用場景 |
|---|---|---|---|---|
| **Managed Browser** | `openclaw` | OpenClaw 啟動並管理專屬 Chrome | ★★★ | **日常使用（推薦）** |
| Extension Relay | `chrome` | 透過 Chrome 擴充套件中繼 | ★☆☆ | 需要控制已開啟的頁面 |
| Remote CDP | 自訂 | 連接遠端 CDP endpoint | ★★☆ | 遠端伺服器上的瀏覽器 |

### 本專案使用的模式

我們使用 **Managed Browser**（`openclaw` profile），搭配 Xvfb 虛擬桌面：

```
OpenClaw Gateway
  ↕ CDP (port 18800)
OpenClaw Chrome（獨立 user-data-dir）
  ↕
Xvfb :99（虛擬桌面）
  ↕
x11vnc → VNC 客戶端（手動操作用）
```

---

## 設定參考

### 目前的設定（`~/.openclaw/openclaw.json`）

```jsonc
{
  "browser": {
    "enabled": true,
    "executablePath": "/usr/bin/google-chrome-stable",
    "headless": false,        // 在虛擬桌面顯示，VNC 可見
    "noSandbox": true,        // Linux 環境需要
    "defaultProfile": "openclaw"
  }
}
```

### 設定項說明

| 設定 | 說明 | 預設值 |
|---|---|---|
| `browser.enabled` | 啟用瀏覽器控制 | `true` |
| `browser.executablePath` | Chrome 執行檔路徑 | 自動偵測 |
| `browser.headless` | 無頭模式（不顯示 GUI） | `false` |
| `browser.noSandbox` | 加入 `--no-sandbox` flag | `false` |
| `browser.defaultProfile` | 預設 browser profile | `chrome` |
| `browser.attachOnly` | 只附加已存在的瀏覽器 | `false` |
| `browser.color` | 瀏覽器 UI 色調 | `#FF4500` |

### 修改設定

```bash
# 單項修改
openclaw config set browser.headless false

# 查看設定
openclaw config get browser
```

---

## 完整 CLI 指令參考

所有指令都支援 `--browser-profile <name>` 和 `--json`（機器可讀輸出）。

以下簡寫 `ob` 代表 `openclaw browser --browser-profile openclaw`。

### 基本操作

```bash
ob status              # 查看瀏覽器狀態
ob start               # 啟動瀏覽器
ob stop                # 停止瀏覽器
```

### 分頁管理

```bash
ob tabs                           # 列出所有分頁
ob tab                            # 目前分頁資訊
ob tab new                        # 新增空白分頁
ob tab select 2                   # 切換到第 2 個分頁
ob tab close 2                    # 關閉第 2 個分頁
ob open https://example.com       # 在新分頁開啟網址
ob focus <targetId>               # 切換到指定分頁（by targetId）
ob close <targetId>               # 關閉指定分頁
```

### 頁面檢視

```bash
ob snapshot                          # AI snapshot（含 ref 編號，可用於操作）
ob snapshot --format aria --limit 200  # ARIA 無障礙樹（僅檢視）
ob snapshot --interactive --compact    # 互動元素列表（role ref 如 e12）
ob snapshot --efficient                # 精簡模式
ob snapshot --labels                   # 含標籤的截圖
ob snapshot --selector "#main"         # 限定 CSS 選擇器範圍
ob screenshot                          # 截圖
ob screenshot --full-page              # 全頁截圖
ob screenshot --ref 12                 # 特定元素截圖
ob console --level error               # 查看 console 錯誤
ob errors --clear                      # 查看並清除頁面錯誤
ob requests --filter api --clear       # 查看 API 請求
ob pdf                                 # 儲存為 PDF
```

### 頁面操作

```bash
ob navigate https://example.com     # 當前分頁導航到 URL
ob click 12                         # 點擊 ref 12 的元素
ob click 12 --double                # 雙擊
ob click e12                        # 點擊 role ref e12
ob type 23 "hello"                  # 在 ref 23 輸入文字
ob type 23 "hello" --submit         # 輸入並送出（Enter）
ob press Enter                      # 按鍵盤鍵
ob hover 44                         # 滑鼠懸停
ob drag 10 11                       # 從 ref 10 拖到 ref 11
ob select 9 OptionA OptionB         # 選擇下拉選項
ob scrollintoview e12               # 捲動到元素可見
ob resize 1280 720                  # 調整視窗大小
```

### 表單操作

```bash
# 批次填寫表單
ob fill --fields '[{"ref":"1","type":"text","value":"Ada"},{"ref":"2","type":"text","value":"test@example.com"}]'
```

### 等待條件

```bash
ob wait --text "Done"                    # 等待文字出現
ob wait "#main"                          # 等待選擇器可見
ob wait --url "**/dashboard"             # 等待 URL 匹配
ob wait --load networkidle               # 等待網路閒置
ob wait --fn "window.ready===true"       # 等待 JS 條件
ob wait "#main" --url "**/dash" --load networkidle --timeout-ms 15000  # 組合條件
```

### 檔案上傳/下載

```bash
ob upload /tmp/file.pdf              # 預備上傳（先呼叫再點擊上傳按鈕）
ob download e12 report.pdf           # 點擊元素並儲存下載
ob waitfordownload report.pdf        # 等待下載完成
```

### 對話框處理

```bash
ob dialog --accept                   # 預備接受下一個 alert/confirm
ob dialog --accept false             # 預備取消
# 注意：先呼叫 dialog，再觸發會產生對話框的操作
```

### Cookie / Storage / 狀態

```bash
# Cookies
ob cookies                                                # 查看所有 cookies
ob cookies set session abc123 --url "https://example.com"  # 設定 cookie
ob cookies clear                                           # 清除所有 cookies

# LocalStorage / SessionStorage
ob storage local get                   # 查看 localStorage
ob storage local set theme dark        # 設定值
ob storage session clear               # 清除 sessionStorage

# 環境設定
ob set offline on                      # 模擬離線
ob set offline off                     # 恢復連線
ob set headers --json '{"X-Debug":"1"}'  # 設定自訂 headers
ob set credentials user pass           # HTTP Basic Auth
ob set credentials --clear             # 清除認證
ob set geo 37.7749 -122.4194 --origin "https://example.com"  # 模擬地理位置
ob set media dark                      # 深色模式
ob set timezone America/New_York       # 時區
ob set locale zh-TW                    # 語言區域
ob set device "iPhone 14"              # 模擬裝置
```

### Debug 工具

```bash
ob highlight e12              # 高亮元素（確認 ref 對應的是什麼）
ob evaluate --fn '(el) => el.textContent' --ref 7   # 執行 JS
ob trace start                # 開始錄製 trace
ob trace stop                 # 停止錄製（輸出 TRACE:<path>）
ob responsebody "**/api" --max-chars 5000  # 查看 API 回應內容
```

---

## Snapshot 與 Ref 系統

OpenClaw 用 **ref**（參考編號）來定位頁面元素，而不是 CSS 選擇器。

### 兩種 Snapshot 模式

| 模式 | 指令 | Ref 格式 | 用途 |
|---|---|---|---|
| AI Snapshot | `snapshot` | 數字（如 `12`） | 預設模式，最常用 |
| Role Snapshot | `snapshot --interactive` | `e` + 數字（如 `e12`） | 互動元素列表 |

### 使用流程

```bash
# 1. 擷取 snapshot，取得 ref 編號
ob snapshot

# 2. 用 ref 操作元素
ob click 12
ob type 23 "hello world"

# 如果操作失敗，重新 snapshot 取得新的 ref
ob snapshot
ob click 15
```

> **重要**：Ref 在頁面導航後會失效，需要重新 snapshot 取得新的 ref。

---

## Debug 工作流程

當操作失敗時（如 "not visible"、"strict mode violation"、"covered"）：

```bash
# 1. 重新取得互動元素列表
ob snapshot --interactive

# 2. 嘗試用 role ref 操作
ob click e12

# 3. 如果還是失敗，高亮看看 Playwright 在定位什麼
ob highlight e12

# 4. 檢查頁面錯誤
ob errors --clear

# 5. 檢查 API 請求
ob requests --filter api --clear

# 6. 深度 debug：錄製 trace
ob trace start
# ... 重現問題 ...
ob trace stop
```

---

## Profiles 管理

```bash
# 列出所有 profiles
openclaw browser profiles

# 建立新 profile
openclaw browser create-profile --name work --color "#0066CC"

# 刪除 profile
openclaw browser delete-profile --name work

# 重設 profile（移至 Trash）
openclaw browser reset-profile --browser-profile openclaw

# 使用指定 profile
openclaw browser --browser-profile work tabs
```

---

## 與 VNC Chrome 共存

本專案中有兩個 Chrome 實例在同一個虛擬桌面上：

| | VNC Chrome | OpenClaw Chrome |
|---|---|---|
| 用途 | 手動瀏覽、一般上網 | OpenClaw 自動化控制 |
| 啟動方式 | `start-vnc-chrome.sh` | `openclaw browser start` |
| User Data | `~/.config/google-chrome/` | `~/.openclaw/browser/openclaw/user-data` |
| CDP Port | 無 | 18800 |
| PID 追蹤 | `/tmp/vnc-chrome.pid` | OpenClaw 自行管理 |
| 停止方式 | `stop-vnc-chrome.sh` | `openclaw browser stop` |
| UI 識別 | 一般 Chrome 外觀 | 橘色 UI 色調 |

**互不干擾**：兩個 Chrome 使用不同的 user-data-dir，各自獨立。

### 只停止 VNC Chrome

```bash
./stop-vnc-chrome.sh --chrome-only   # 保留 Xvfb（OpenClaw 需要）
```

### 完全停止 VNC 環境

```bash
./stop-vnc-chrome.sh                 # 會提醒你 OpenClaw browser 也會受影響
```

---

## 安全注意事項

- OpenClaw 的 browser profile 可能包含已登入的 session，視為敏感資料
- `evaluate` 和 `wait --fn` 會在頁面執行任意 JavaScript，注意 prompt injection 風險
- 如不需要 JS 執行功能，可停用：`openclaw config set browser.evaluateEnabled false`
- 瀏覽器控制服務只綁定 loopback，不會暴露到外部網路
- 保護 Gateway token，不要外流
