#!/bin/bash
# 初始化 workspace Git repo（Phase 1 第一層）
# 用法: ./init-workspace.sh [github_remote_url]
# 例: ./init-workspace.sh https://github.com/YourOrg/openclaw-workspace.git
#
# 需先設定 git config user.email 和 user.name

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
REMOTE="${1:-}"

if [ ! -d "$WORKSPACE" ]; then
  echo "錯誤：workspace 不存在: $WORKSPACE"
  echo "請先完成 OpenClaw onboarding"
  exit 1
fi

cd "$WORKSPACE"

# .gitignore
cat > .gitignore << 'EOF'
*.log
.cache/
node_modules/
browser-data/
tmp/
*.key
*.pem
credentials/
secrets/
EOF

# git init（若尚未）
if [ ! -d .git ]; then
  git init
fi

git add -A
git status

# 必須有 commit 才能 push
git diff --cached --quiet || git commit -m "v0.0: baseline - onboard completed"

if [ -n "$REMOTE" ]; then
  git branch -M main
  git remote remove origin 2>/dev/null || true
  git remote add origin "$REMOTE"
  echo "已設定 remote: $REMOTE"
  echo "請執行: cd $WORKSPACE && git push -u origin main"
fi

echo "Workspace Git 初始化完成"
