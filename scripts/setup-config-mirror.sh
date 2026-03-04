#!/bin/bash
# 建立 _config-mirror 脫敏鏡像（在 workspace 內）
# 用法: ./setup-config-mirror.sh
# 前置: OpenClaw 已安裝，~/.openclaw/workspace 存在

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MIRROR_DIR="$WORKSPACE/_config-mirror"

mkdir -p "$MIRROR_DIR"

cat > "$MIRROR_DIR/sync-config.sh" << 'SCRIPT'
#!/bin/bash
# 複製 openclaw.json 並移除敏感資訊
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
MIRROR_DIR="$(dirname "$0")"

if command -v jq &> /dev/null; then
  jq 'del(.credentials) | del(.gateway.auth.token) | del(.channels.discord.token) |
      (if .channels.discord.accounts then .channels.discord.accounts |= with_entries(.value |= del(.token)) else . end) |
      walk(if type == "string" and (test("^sk-") or test("^AIza") or test("^MTQ")) then "REDACTED" else . end)' \
    "$OPENCLAW_HOME/openclaw.json" > "$MIRROR_DIR/openclaw.json"
else
  echo "警告：未安裝 jq，直接複製（注意不要 push 到公開 repo）"
  cp "$OPENCLAW_HOME/openclaw.json" "$MIRROR_DIR/openclaw.json"
fi

if command -v openclaw &> /dev/null; then
  openclaw cron list --json > "$MIRROR_DIR/cron-jobs.json" 2>/dev/null || true
fi

echo "Config synced (sanitized) at $(date)"
SCRIPT

chmod +x "$MIRROR_DIR/sync-config.sh"
echo "已建立 $MIRROR_DIR/sync-config.sh"
echo "執行: bash $MIRROR_DIR/sync-config.sh"
