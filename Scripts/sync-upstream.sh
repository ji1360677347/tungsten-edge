#!/bin/bash
# 把上游 moonbai-studio/tungsten-edge 的更新同步进 iBar。
#
# 分支约定：
#   master  只做上游镜像，永远不提交本地改动（只允许 fast-forward）
#   main    iBar 开发主线
#
# 用法：./Scripts/sync-upstream.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> 拉取上游"
git fetch upstream --tags --prune

echo "==> 同步 master（仅快进）"
git checkout master
if ! git merge --ff-only upstream/master; then
  echo "!! master 有本地提交，无法快进。master 必须保持与上游一致。" >&2
  echo "   排查：git log --oneline upstream/master..master" >&2
  exit 1
fi
git push origin master

echo "==> 把上游更新并入 main"
git checkout main
BEHIND=$(git rev-list --count main..master)
if [ "$BEHIND" -eq 0 ]; then
  echo "main 已包含全部上游提交，无需合并。"
else
  echo "上游有 $BEHIND 个新提交，开始合并…"
  git merge master --no-edit || {
    echo "!! 合并冲突，请手动解决后 git commit" >&2
    exit 1
  }
fi

echo "==> 完成。当前：$(git log --oneline -1)"
