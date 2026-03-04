## 1. 架構總覽（單 Agent）

> **適用對象**：一般上班族、經理主管，建立個人 AI 助理  
> **本指南**：聚焦單 Agent 架構，不涵蓋多 Agent 團隊

### 1.1 系統架構

```
通訊頻道（Discord / Telegram / Web UI）
        │
        ▼
┌──────────────────────────────────────┐
│     Gateway (Node.js :18789)         │
│     Tailscale Serve 對外暴露          │
│                                      │
│  Main Agent（你的 AI 助理）           │
└──────────┬───────────────────────────┘
           │
           ▼
     Main Agent
     (單一 workspace)
     
AI Provider: 依 Onboarding 選擇（如 Moonshot Kimi、Google Gemini、OpenAI）
```

### 1.2 關鍵資料夾結構

`~/.openclaw/` 包含兩類性質截然不同的資料，這是備份策略的核心前提：

```
~/.openclaw/
│
│  ╔══════════════════════════════════════════════╗
│  ║  State（管線）— 設定、credentials、sessions  ║
│  ║  含敏感資料，不適合直接 Git 版控              ║
│  ╚══════════════════════════════════════════════╝
│
├── openclaw.json          ← 核心設定
├── credentials/           ← API keys、OAuth tokens（🔴 極高敏感）
├── channels/              ← Discord/Telegram tokens、session files
├── agents/                ← Agent-level state
├── browser/               ← Chrome profile data、cookies
├── skills/                ← Shared skills
├── cron/                  ← Cron job 定義
├── config-backups/        ← Golden config（建議建立）
│
│  ╔══════════════════════════════════════════════╗
│  ║  Workspace（大腦）— 你的工作空間             ║
│  ║  Markdown 為主，適合 Git 精確版控             ║
│  ╚══════════════════════════════════════════════╝
│
└── workspace/             ← Main Agent 工作目錄
    ├── SOUL.md / USER.md / AGENTS.md / TOOLS.md / IDENTITY.md
    ├── HEARTBEAT.md
    ├── memory/
    ├── _config-mirror/    ← 脫敏版 config 鏡像（可選）
    └── (你的工作檔案目錄...)
```

### 1.3 三層備份體系總覽

```
┌─────────────────────────────────────────────────────┐
│  第一層：Git 精確版控                                │
│  範圍：workspace 獨立 repo + 脫敏 config 鏡像        │
│  工具：Git + GitHub（private repo）                 │
│  頻率：每次變更                                      │
│  用途：精確追蹤每一次改動，秒級回滾                   │
├─────────────────────────────────────────────────────┤
│  第二層：Golden Config 機制                          │
│  範圍：openclaw.json                                │
│  工具：cp 手動                                      │
│  頻率：每次確認可用後                                │
│  用途：config 改壞了一秒恢復                         │
├─────────────────────────────────────────────────────┤
│  第三層：加密全量備份                                │
│  範圍：整個 .openclaw（排除 browser/sessions）       │
│  工具：tar + gpg + 系統 crontab                     │
│  頻率：每日凌晨                                      │
│  用途：VM 掛了也能完整恢復                           │
└─────────────────────────────────────────────────────┘
```

### 1.4 各檔案備份屬性速查

| 檔案/目錄 | 變更頻率 | 敏感度 | Git 友善度 | 備份層級 |
|-----------|---------|--------|-----------|---------|
| SOUL.md | 低 | 低 | ✅ 極好 | 第一層 Git |
| USER.md | 低 | 中（個資） | ✅ 好 | 第一層 Git |
| AGENTS.md | 低 | 低 | ✅ 極好 | 第一層 Git |
| HEARTBEAT.md | 中 | 低 | ✅ 好 | 第一層 Git |
| memory/*.md | 高（每天新增） | 中 | ⚠️ 持續增長 | 第一層 Git |
| openclaw.json | 低-中 | 中 | ✅ 好 | 第二層 Golden + 脫敏鏡像入 Git |
| credentials/ | 極低 | 🔴 極高 | ❌ 絕對不行 | 第三層加密備份 |
| browser/ | 高 | 高（cookies） | ❌ binary | 排除（可重建） |
