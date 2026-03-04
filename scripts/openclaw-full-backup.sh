#!/bin/bash
# OpenClaw 加密全量備份（第三層）
# 用法: ./openclaw-full-backup.sh
# 前置: 需已建立 ~/.openclaw-backup-passphrase
#
# 建議加入 crontab: 0 3 * * * $HOME/openclaw-scripts/openclaw-full-backup.sh >> $HOME/openclaw-backups/backup.log 2>&1

set -euo pipefail

BACKUP_DIR="${OPENCLAW_BACKUP_DIR:-$HOME/openclaw-backups}"
PASSPHRASE_FILE="${OPENCLAW_PASSPHRASE_FILE:-$HOME/.openclaw-backup-passphrase}"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

if [ ! -f "$PASSPHRASE_FILE" ]; then
  echo "錯誤：找不到密碼檔 $PASSPHRASE_FILE"
  echo "請先執行: openssl rand -base64 32 > $PASSPHRASE_FILE && chmod 600 $PASSPHRASE_FILE"
  echo "並將密碼存到密碼管理器！"
  exit 1
fi

# 打包（排除 browser data 和 sandboxes，太大且可重建）
tar czf "/tmp/openclaw-backup-${DATE}.tar.gz" \
  --exclude='.openclaw/browser' \
  --exclude='.openclaw/sandboxes' \
  --exclude='.openclaw/agents/*/sessions' \
  -C "$HOME" .openclaw

# 加密
gpg --batch --yes --symmetric --cipher-algo AES256 \
  --passphrase-file "$PASSPHRASE_FILE" \
  --output "${BACKUP_DIR}/openclaw-backup-${DATE}.tar.gz.gpg" \
  "/tmp/openclaw-backup-${DATE}.tar.gz"

# 清理明文
rm "/tmp/openclaw-backup-${DATE}.tar.gz"

# 保留最近 7 份
ls -1t "${BACKUP_DIR}"/openclaw-backup-*.gpg 2>/dev/null | tail -n +8 | xargs -r rm

echo "[$(date)] Encrypted backup complete: openclaw-backup-${DATE}.tar.gz.gpg"
