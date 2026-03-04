## 5.5 Phase 3.5：版控工作流驗證（單 Agent）

> **前置**：[Phase 3](05-phase3-core-markdown.md) 已完成 USER.md、AGENTS.md、TOOLS.md。  
> **重要**：在進入進階設定前，先驗證版控流程。單 Agent 階段由你負責版控。

### 5.5.1 驗證流程

```bash
cd ~/.openclaw/workspace

# 1. 確認在 main 且乾淨
git status && git checkout main

# 2. 測試 experiment branch 流程
git checkout -b experiment/test-version-control
echo "test" > _version-control-test.txt
git add _version-control-test.txt && git commit -m "test: 驗證 branch 流程"
git checkout main
git branch -D experiment/test-version-control
rm -f _version-control-test.txt

# 3. 測試 tag 流程
git tag -a v0.5-verify-test -m "test: tag creation"
git tag -l
git tag -d v0.5-verify-test

# 4. 驗證 sync-config.sh（若 _config-mirror 已建立則執行）
[ -f ~/.openclaw/workspace/_config-mirror/sync-config.sh ] && bash ~/.openclaw/workspace/_config-mirror/sync-config.sh
git status
```

### 5.5.2 確認 AGENTS.md 中的 Git 版控段落

AGENTS.md 應包含「每次 heartbeat 時，如果 workspace 有未 commit 的變更」的 auto backup 指令。

**若尚未啟用 heartbeat**（Phase 4 未執行）：
- 在 DM 問 Agent：「你讀過 AGENTS.md 的 Git 版控段落嗎？當有 heartbeat 時，workspace 有未 commit 變更的話，你會做什麼？」
- 若回答正確（會執行 `git add -A && git commit -m "auto: heartbeat backup" && git push`）即通過

### 5.5.3 完成後打 tag

```bash
cd ~/.openclaw/workspace
git add -A
git commit -m "v0.5.1: Phase 3.5 version control workflow verification complete"
git tag -a v0.5-stable -m "Single Agent version control verified, ready for Phase 4"
git push
git push --tags
```
