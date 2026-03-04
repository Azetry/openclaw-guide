## 9. Troubleshooting

| 問題 | 解法 |
|------|------|
| Gateway 無法啟動 | `openclaw doctor` → 檢查 Node.js 版本和 port 佔用 |
| Tailscale Web UI "origin not allowed" | `openclaw config set gateway.controlUi.allowedOrigins '["https://你的.ts.net"]' --strict-json` |
| Discord Bot 沒回應 | 確認 Bot 的 Message Content Intent 有開、Token 正確 |
| Discord DM 無法對話 | Pairing 模式需先 `openclaw devices approve [id]` |
| Heartbeat 不觸發 | 確認 `every` 不是 `"0m"`，檢查 activeHours |
| Heartbeat 太吵 | HEARTBEAT.md 最後加 "沒事就 HEARTBEAT_OK" |
| Cron 沒執行 | `openclaw cron list` 確認狀態，`openclaw cron trigger` 手動測試 |
| Browser 無法啟動 | `openclaw browser status`，確認 Chrome 和 Playwright 依賴 |
| **Browser 反 bot 被擋** | **改用非 headless 模式：先啟動 VNC（`start-vnc-chrome.sh`），再執行 `setup-openclaw-browser.sh`** |
| **VNC 連不上** | **確認 Xvfb 在跑（`pgrep Xvfb`）、SSH 轉發正確（`ssh -L 5900:localhost:5900`）** |
| 配置改壞了 | `cp config-backups/openclaw.json.golden openclaw.json && openclaw gateway restart` |
| Workspace 改壞了 | `git checkout v穩定版-stable` |
| 整台 VM 掛了 | gpg 解密全量備份 → tar 解壓 → git clone workspace repo |

**診斷指令**：

```bash
openclaw doctor              # 全面健康檢查
openclaw status              # Gateway 狀態
openclaw cron list           # Cron 列表
openclaw skills list         # Skills 列表
openclaw devices list        # 已配對裝置
openclaw browser status      # Browser 狀態
tailscale status             # Tailscale 連線狀態
```
