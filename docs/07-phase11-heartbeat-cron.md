## 7. Phase 11：Heartbeat 與 Cron 自動化

> **閱讀時機**：本 Phase 可在完成 Phase 4 後進行。

### 7.1 HEARTBEAT.md — 定期巡檢清單

> **原則：保持精簡，避免 token 爆炸。** 每次 heartbeat 都會載入此檔案。  
> **請依你的工作性質調整**，以下為上班族/主管適用公版：

```markdown
# HEARTBEAT.md

## 待辦任務
- 檢查 workspace 中 tasks/ 或 active-tasks.md 是否有未完成項目
- 若有且使用者不在休息時段，繼續推進

## 會議與日程
- 檢查今日是否有需準備的會議或待回覆事項
- 有重要提醒時通知使用者

## 系統健康
- 確認 browser 和 skills 正常運作

## 如果以上都沒有需要處理的事項，回覆 HEARTBEAT_OK
```

**其他可選巡檢項目**（依需求加入）：
- 市場/產業動態（若有追蹤）
- 郵件或通知摘要
- 專案進度檢查

```bash
cd ~/.openclaw/workspace
git add HEARTBEAT.md
git commit -m "v0.6: HEARTBEAT.md - 巡檢清單"
git push
```

### 7.2 Cron Jobs — 精確排程

> **請依你的時區與作息調整**，以下為公版範例：

```bash
# ===== 每日早報 =====
openclaw cron add \
  --name "Morning Briefing" \
  --cron "0 8 * * *" \
  --tz "Asia/Taipei" \
  --session isolated \
  --model "moonshot/kimi-k2.5" \
  --message "產出今日早報：
    1) 昨日重點回顧
    2) 今日待辦清單
    3) 需要決策的事項
    整理成簡潔 briefing 發送給我。" \
  --announce

# ===== 每日收盤/下班摘要（上班族）=====
openclaw cron add \
  --name "End of Day Summary" \
  --cron "0 18 * * 1-5" \
  --tz "Asia/Taipei" \
  --session isolated \
  --model "moonshot/kimi-k2.5" \
  --message "整理今日工作摘要：
    1) 完成事項
    2) 未完成待辦
    3) 明日需注意事項
    存入 workspace/daily-briefing/ 並發送摘要。" \
  --announce

# ===== 每週週報 =====
openclaw cron add \
  --name "Weekly Report" \
  --cron "0 10 * * 0" \
  --tz "Asia/Taipei" \
  --session isolated \
  --model "moonshot/kimi-k2.5" \
  --thinking high \
  --message "產出本週週報：
    1) 本週工作回顧與關鍵事件
    2) 重要進展與成果
    3) 下週展望與需要關注的事項
    存入 workspace/weekly-reports/ 並發送摘要。" \
  --announce

# ===== 每日 workspace git 備份 =====
# 1. 複製腳本到 ~/openclaw-scripts
mkdir -p ~/openclaw-scripts
cp ~/openclaw-guide/scripts/openclaw-git-backup.sh ~/openclaw-scripts/
chmod +x ~/openclaw-scripts/openclaw-git-backup.sh

# 2. 加入 Cron（由 Agent 觸發執行）
openclaw cron add \
  --name "Daily Git Backup" \
  --cron "0 2 * * *" \
  --tz "Asia/Taipei" \
  --session isolated \
  --model "moonshot/kimi-k2.5" \
  --message "執行 bash ~/openclaw-scripts/openclaw-git-backup.sh，完成後回報狀態。" \
  --announce
```

> **注意**：`--model` 請改為你 Onboarding 時選擇的 model。`--tz` 請改為你的時區。

### 7.3 設定完成後同步 cron 列表到 Git

```bash
# 若有 _config-mirror
openclaw cron list --json > ~/.openclaw/workspace/_config-mirror/cron-jobs.json

cd ~/.openclaw/workspace
git add _config-mirror/cron-jobs.json
git commit -m "cron: 初始 cron jobs 設定完成"
git push
```

### 7.4 查看與管理 Cron

```bash
openclaw cron list                           # 列出所有
openclaw cron pause --name "Morning Briefing" # 暫停
openclaw cron resume --name "Morning Briefing" # 恢復
openclaw cron remove --name "Morning Briefing" # 刪除
openclaw cron trigger --name "Morning Briefing" # 手動觸發測試
```
