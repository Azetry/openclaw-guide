#!/bin/bash
# 恢復 Golden Config（openclaw.json 改壞時）
# 用法: ./restore-golden-config.sh

set -e

GOLDEN="${OPENCLAW_CONFIG_GOLDEN:-$HOME/.openclaw/config-backups/openclaw.json.golden}"
TARGET="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

if [ ! -f "$GOLDEN" ]; then
  echo "錯誤：找不到 Golden config: $GOLDEN"
  echo "請確認已執行 Phase 1 建立 Golden Config"
  exit 1
fi

cp "$GOLDEN" "$TARGET"
echo "已恢復 Golden config"

if command -v openclaw &> /dev/null; then
  openclaw gateway restart
  echo "Gateway 已重啟"
fi
