## 8. Phase 8：Workspace 檔案結構

> **閱讀時機**：本 Phase 可在完成 Phase 4 後進行。

請 Agent 建立以下工作檔案，**請依你的工作性質調整**：

```
~/.openclaw/workspace/
├── SOUL.md              ← Phase 2 Bootstrap
├── IDENTITY.md          ← Phase 2 Bootstrap
├── USER.md              ← Phase 3
├── AGENTS.md            ← Phase 3
├── TOOLS.md             ← Phase 3
├── HEARTBEAT.md         ← Phase 7
├── _config-mirror/      ← 脫敏版 config 鏡像（若有）
├── memory/
├── tasks/               ← 任務追蹤
│   └── active-tasks.md
├── daily-briefing/      ← 每日簡報
├── weekly-reports/      ← 每週報告
├── meetings/            ← 會議紀錄（可選）
└── decisions/           ← 決策紀錄（可選）
```

**建立方式**——直接告訴 Agent：

```
請建立以下 workspace 檔案結構：
- tasks/active-tasks.md（任務追蹤，初始為空 template）
- daily-briefing/（每日簡報目錄）
- weekly-reports/（每週報告目錄）
- meetings/（會議紀錄目錄，可選）
- decisions/（決策紀錄目錄，可選）

每個 .md 檔案建立基本 template，我之後再填入內容。
```

```bash
cd ~/.openclaw/workspace
git add -A
git commit -m "v0.7: workspace 檔案結構建立完成"
git push
```
