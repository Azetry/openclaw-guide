# OpenClaw + Tailscale Serve 安裝與設定指南

這份指南整理了在 Linux 環境下安裝 OpenClaw 並透過 Tailscale Serve 公開服務的完整步驟。

## 1. 前置準備

確保您已經安裝 Tailscale 並登入：
```bash
tailscale up
```

## 2. 安裝 OpenClaw

執行官方安裝指令：
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

安裝完成後，依照終端機提示進行初始化設定：
1.  選擇 **Local gateway**。
2.  設定 **Workspace directory** (預設即可)。
3.  選擇 **Model/auth provider** (如 OpenAI)。
4.  完成瀏覽器驗證流程。
5.  記下預設 Port (通常為 **18789**)。
6.  **建議**：當被問及是否安裝 Gateway Service 時，選擇 `Yes`，這樣 OpenClaw 就會作為 systemd 服務在背景自動執行，即使關閉終端機也不會中斷。

## 3. 設定 Tailscale 權限 (關鍵步驟)

為了讓目前使用者可以直接操作 Tailscale Serve 而不需每次使用 sudo，請執行以下指令設定 Operator 權限：

```bash
sudo tailscale set --operator=$USER
```
*(這會允許您當前的使用者帳號管理 Tailscale 設定，解決 `Access denied` 的問題)*

## 4. 啟動 Tailscale Serve

將 OpenClaw 的本地服務 (Port 18789) 透過 Tailscale 安全地分享出去。

執行以下指令 (使用 `--bg` 讓它在背景執行)：
```bash
tailscale serve --bg http://localhost:18789
```

*注意：如果是第一次在您的 Tailnet 使用 Serve 功能，終端機可能會顯示一個網址，要求您先至 Tailscale 管理後台啟用 HTTPS 功能。請複製該網址並在瀏覽器中開啟以完成啟用。*

## 5. 取得 Gateway Token 並連接 Dashboard

在透過 Tailscale 網址連接前，您需要先取得 Gateway Token：

1.  **取得 Token 與連接網址**：
    在終端機執行：
    ```bash
    openclaw dashboard --no-open
    ```
    您會看到類似以下的輸出：
    ```
    Dashboard link (with token):
    http://127.0.0.1:18789/#token=acaa78d6f485bcf549328c415b66ee94741de07274cf6181
    ```

2.  **組合正確的連線網址**：
    將上述 Token (`#token=...` 及其後面的字串) 複製起來，並附加到您的 Tailscale 網址後方：

    `https://<您的Tailscale網址>.ts.net/#token=<您的Token>`

    **例如：**
    `https://neurowatt-molta-229.tail8cb631.ts.net/#token=acaa78d6f485bcf549328c415b66ee94741de07274cf6181`

3.  **在瀏覽器開啟該網址**。

## 6. 裝置配對與授權 (Device Pairing)

當您首次開啟上述含有 Token 的網址時，Dashboard 仍可能會顯示 "Pairing Required" 或 "Disconnected"。請依照以下步驟批准該裝置：

1.  **列出等待中的請求**：
    在 OpenClaw 主機的終端機執行：
    ```bash
    openclaw devices list
    ```
    您會看到類似以下的列表，請找出剛剛發出的請求 (Request ID)：
    ```
    Pending (1)
    ┌─────────┬────────┬────────┬────────────┐
    │ Request │ Device │ Role   │ Age        │
    ├─────────┼────────┼────────┼────────────┤
    │ 54656ad │ e6aefe │ operat │ 3m ago     │
    │ 4-7a07- │ 5eba17 │ or     │            │
    │ 4a38-   │ ...... │        │            │
    └─────────┴────────┴────────┴────────────┘
    ```

2.  **批准請求**：
    複製完整的 **Request ID** (注意：如果終端機有斷行，請將其拼湊成完整的 UUID 字串，不要有空格)，然後執行批准指令：

    ```bash
    openclaw devices approve <您的完整RequestID>
    ```

    例如：
    ```bash
    openclaw devices approve 54656ad4-7a07-4a38-afc6-d5112c78b3fb
    ```

批准成功後，重新整理瀏覽器頁面，您應該就能順利進入 Dashboard 了。

## 7. Telegram 帳號配對 (Telegram Pairing)

如果您在 OpenClaw 中設定了 Telegram Bot，首次與 Bot 對話時可能會要求配對：

1.  **列出 Telegram 配對請求**：
    ```bash
    openclaw pairing list telegram
    ```
    輸出範例：
    ```
    Pairing requests (1)
    ┌──────────┬────────────────┬───────┐
    │ Code     │ telegramUserId │ ...   │
    ├──────────┼────────────────┼───────┤
    │ JADU694B │ 6340927034     │ ...   │
    └──────────┴────────────────┴───────┘
    ```

2.  **批准請求**：
    **重要**：請使用 `Code` 欄位的值 (例如 `JADU694B`) 進行批准，**不要**使用 `telegramUserId`。

    ```bash
    openclaw pairing approve telegram <Code>
    ```

    例如：
    ```bash
    openclaw pairing approve telegram JADU694B
    ```

## 8. 驗證與存取

設定完成後，您可以使用以下指令查看目前的公開網址：

```bash
tailscale serve status
```

您將會看到類似以下的 HTTPS 網址：
`https://<您的機器名稱>.<您的Tailnet名稱>.ts.net/`

現在，您可以在任何連線到同一個 Tailscale 網路的裝置上，透過該網址 (記得加上 Token) 存取您的 OpenClaw 服務。

---

### 常用指令

*   **停止分享**：
    ```bash
    tailscale serve --https=443 off
    ```
*   **查看 OpenClaw 狀態** (確認 Port 是否聆聽中)：
    ```bash
    ss -tuln | grep 18789
    ```
*   **查看 OpenClaw 服務日誌** (如果安裝時已啟用 systemd)：
    ```bash
    journalctl --user -u openclaw-gateway -f
    ```
