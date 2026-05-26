#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed. Install Git first."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed. Install gh to use this script."
  exit 1
fi

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run 'gh auth login' first."
  exit 1
fi

repo_name=$(basename "$PWD")
visibility=${GITHUB_REPO_VISIBILITY:-public}
description=${GITHUB_REPO_DESCRIPTION:-"${repo_name} project uploaded from local workspace."}

if [ ! -d .git ]; then
  git init
fi

git add .

if ! git diff --cached --quiet; then
  git commit -m "Initial commit"
else
  echo "No staged changes to commit."
fi

current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)
if [ -z "$current_branch" ]; then
  git branch -M main
  current_branch=main
else
  git branch -M main
  current_branch=main
fi

if ! git remote | grep -q '^origin$'; then
  if gh repo view "$repo_name" >/dev/null 2>&1; then
    repo_url=$(gh repo view "$repo_name" --json sshUrl -q .sshUrl)
    git remote add origin "$repo_url"
    echo "Added existing GitHub repository as origin: $repo_url"
  else
    gh repo create "$repo_name" --${visibility} --description "$description" --confirm
    repo_url=$(gh repo view "$repo_name" --json sshUrl -q .sshUrl)
    git remote add origin "$repo_url"
    echo "Created GitHub repository '$repo_name' and added origin: $repo_url"
  fi
fi

git push -u origin "$current_branch"
echo "Pushed branch '$current_branch' to origin."