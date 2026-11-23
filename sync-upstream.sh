#!/usr/bin/env bash
# 同步 Tencent/LoopForge 官方更新：upstream -> main -> custom -> fork
# 用法: ./sync-upstream.sh   （需要 DSH_SECRET_GITHUB_WRITE_TOKEN 才能推送 fork）
# 注意：token 需要 Contents:write；若上游改动了 .github/workflows，还需要 Workflows:write，否则 push 被拒。
# upstream 走 ghfast.top 镜像（直连 github.com 不稳定），origin 直连推送。
set -euo pipefail
cd "$(dirname "$0")"
BRANCH="${CUSTOM_BRANCH:-custom}"
TOKEN="${DSH_SECRET_GITHUB_WRITE_TOKEN:-${DSH_SECRET_GITHUB_PUSH_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  echo "跳过推送：未设置 DSH_SECRET_GITHUB_WRITE_TOKEN"
fi

CRED='!f() { echo "username=x-access-token"; echo "password=$GIT_TOKEN"; }; f'

retry() { # 最多 3 次，间隔 5 秒（github 直连偶发 TLS 中断）
  local i=1
  until "$@"; do
    [ "$i" -ge 3 ] && return 1
    echo "  第 $i 次失败，5 秒后重试..." >&2
    sleep 5
    i=$((i + 1))
  done
}

fetch_upstream() { git fetch upstream --tags --prune; }
push_origin() { GIT_TOKEN="$TOKEN" git -c credential.helper="$CRED" push origin main "$BRANCH"; }

retry fetch_upstream

git checkout main
git merge --ff-only upstream/main

git checkout "$BRANCH"
git merge --no-edit main

if [ -n "$TOKEN" ]; then
  retry push_origin
fi

echo "同步完成: $(git log -1 --oneline)"
