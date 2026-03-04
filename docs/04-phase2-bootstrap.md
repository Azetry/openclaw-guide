## 4. Phase 2：Bootstrap 身份建立

### 4.0 前置條件：檔案寫入權限

Bootstrap 需要 Agent 能寫入 workspace 的 SOUL.md 和 IDENTITY.md。若 `tools.profile` 為 `messaging`（Onboarding 預設），Agent 僅有訊息工具，無法寫檔。

**先執行**（詳見 [Phase 4](06-phase4-openclaw-json.md)）：
```bash
openclaw config set tools.profile coding
openclaw gateway restart
```

⚠️ **注意**：重新執行 `openclaw onboard` 會覆寫 config，可能把 `tools.profile` 改回 `messaging`。完成 Bootstrap 後避免再跑 onboard。

### 4.1 第一次對話

OpenClaw 安裝完成後第一次啟動，會進入 Bootstrap 儀式。以下為**引導範例**，請依你的需求調整後與 Agent 對話：

<details>
<summary>Bootstrap 對話引導（點擊展開）</summary>

**Agent**（首次上線）：
> Hey. I just came online. Who am I? Who are you?

**你**（範例，請改為你的實際情況）：
> 你是我的 AI 助理。我是 [你的稱呼]，[簡述你的角色，例如：一般上班族 / 專案經理 / 主管]。

**Agent** 會詢問你的偏好，例如：
- 工作風格與互動：你希望 Agent 偏向自動執行並回報，還是每一步都先確認？
- 底線與偏好：關於存取檔案、對外執行操作，你有什麼限制或偏好？

**你**（範例）：
> 工作風格：內部作業（讀檔、搜尋、整理）可自主執行並回報。對外行動（shell、發送、公開）一律先確認。不確定時先問。
>
> 底線：私有資訊絕不外流；破壞性操作（rm、大量刪除）執行前必須確認；不代替我發言，尤其在群組中。
>
> 請把以上邊界與偏好寫進 SOUL.md 的「邊界」區塊，完成後回報已更新。

</details>

### 4.2 若 Agent 卡住或無法寫檔

可手動寫入：參考 4.1 對話紀錄中的 IDENTITY 與 SOUL 設定，由 Cursor 等工具代寫至 `~/.openclaw/workspace/`。

> **注意**：Phase 3 後，記憶相關內容已移至 AGENTS.md，SOUL.md 不再包含該區塊。完整 SOUL 與 AGENTS 結構見 [Phase 3](05-phase3-core-markdown.md)。

### 4.3 確認並 commit

```bash
cat ~/.openclaw/workspace/IDENTITY.md
cat ~/.openclaw/workspace/SOUL.md

cd ~/.openclaw/workspace
git add -A
git commit -m "v0.1: Bootstrap complete - Agent identity established"
git tag -a v0.1-identity -m "Agent identity established (single agent)"
git push --tags
```

> 完成後可進行 [Phase 3](05-phase3-core-markdown.md)（USER.md、AGENTS.md、TOOLS.md）。
