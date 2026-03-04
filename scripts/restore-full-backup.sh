#!/bin/bash
# 從加密全量備份恢復
# 用法: ./restore-full-backup.sh <備份檔案路徑>
# 例: ./restore-full-backup.sh ~/openclaw-backups/openclaw-backup-20260301-030000.tar.gz.gpg

set -e

if [ -z "${1:-}" ]; then
  echo "用法: $0 <備份檔案.gpg>"
  echo "例: $0 ~/openclaw-backups/openclaw-backup-20260301-030000.tar.gz.gpg"
  exit 1
fi

BACKUP_FILE="$1"
if [ ! -f "$BACKUP_FILE" ]; then
  echo "錯誤：找不到檔案 $BACKUP_FILE"
  exit 1
fi

echo "解密並解壓到 $HOME ..."
gpg --decrypt "$BACKUP_FILE" | tar xz -C "$HOME"

echo "恢復完成。請檢查並重啟 Gateway: openclaw gateway restart"
