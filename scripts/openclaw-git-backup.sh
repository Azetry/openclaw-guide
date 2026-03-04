#!/bin/bash
# OpenClaw Git 備份（第一層）
# 用法: ./openclaw-git-backup.sh
# 單 Agent：備份 workspace。若有 _config-mirror 則一併 sync。

set -e

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
DATE=$(date +%Y-%m-%d)

# 1. sync config mirror（若有）
if [ -f "$OPENCLAW_DIR/workspace/_config-mirror/sync-config.sh" ]; then
  bash "$OPENCLAW_DIR/workspace/_config-mirror/sync-config.sh" 2>/dev/null || true
fi

# 2. 備份 workspace
if [ -d "$OPENCLAW_DIR/workspace/.git" ]; then
  (cd "$OPENCLAW_DIR/workspace" && git add -A && (git diff --cached --quiet || git commit -m "auto-backup: $DATE") && git push) 2>/dev/null || true
fi

echo "[$(date)] Git backup complete"
