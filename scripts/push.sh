#!/bin/bash
# ============================================
# Parkinson Monitor — 三平台推送脚本
# 用法: bash scripts/push.sh
# ============================================
set -e

echo "🔧 配置 Git remotes..."

# 替换为实际仓库地址
ATOMGIT_URL="https://atomgit.com/YOUR_ORG/parkinson-monitor.git"
GITHUB_URL="https://github.com/YOUR_ORG/parkinson-monitor.git"
GITLAB_URL="https://gitlab.com/YOUR_ORG/parkinson-monitor.git"

git remote add atomgit "$ATOMGIT_URL" 2>/dev/null || git remote set-url atomgit "$ATOMGIT_URL"
git remote add github "$GITHUB_URL"   2>/dev/null || git remote set-url github "$GITHUB_URL"
git remote add gitlab "$GITLAB_URL"   2>/dev/null || git remote set-url gitlab "$GITLAB_URL"

echo "📦 暂存所有文件..."
git add .

echo "💬 提交..."
git commit -m "Parkinson Monitor v1.0.0 — 帕金森运动障碍可穿戴监测应用" || echo "无新内容可提交"

echo "🚀 推送到 AtomGit..."
git push -u atomgit main

echo "🚀 推送到 GitHub..."
git push -u github main

echo "🚀 推送到 GitLab..."
git push -u gitlab main

echo "✅ 三平台推送完成!"
echo ""
echo "AtomGit: $ATOMGIT_URL"
echo "GitHub:  $GITHUB_URL"
echo "GitLab:  $GITLAB_URL"
