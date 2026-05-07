#!/bin/bash
# Hook: 모듈 CLAUDE.md decay 알림
# Matcher: PostToolUse / Bash
# git commit 직후, 모듈 디렉토리의 누적 변경 라인 또는 CLAUDE.md 의 마지막 수정 경과일이
# 임계치를 넘으면 stderr 로 알림. commit 자체는 차단하지 않음 (exit 0).
set -uo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[ "$tool_name" != "Bash" ] && exit 0
case "$command" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# git 저장소 확인
git rev-parse HEAD >/dev/null 2>&1 || exit 0
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# 마지막 commit 의 변경 파일
changed_files=$(git show --name-only --pretty= HEAD 2>/dev/null || true)
[ -z "$changed_files" ] && exit 0

# 임계치
threshold_lines=200
threshold_days=30
now_epoch=$(date +%s)

# 변경 파일을 가장 가까운 부모 디렉토리 (CLAUDE.md 보유, root 제외) 로 분류
# bash 3.2 호환: associative array 대신 newline 구분 문자열 + sort -u
modules_raw=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  dir=$(dirname "$f")
  while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    if [ -f "$repo_root/$dir/CLAUDE.md" ]; then
      modules_raw="${modules_raw}${dir}"$'\n'
      break
    fi
    parent=$(dirname "$dir")
    [ "$parent" = "$dir" ] && break
    dir="$parent"
  done
done <<< "$changed_files"

modules=$(printf '%s' "$modules_raw" | sort -u | grep -v '^$' || true)
[ -z "$modules" ] && exit 0

warnings=()
while IFS= read -r module_path; do
  [ -z "$module_path" ] && continue
  claude_md="$module_path/CLAUDE.md"

  # 이번 commit 이 모듈 CLAUDE.md 자체를 갱신했다면 skip
  if echo "$changed_files" | grep -qx "$claude_md"; then
    continue
  fi

  # 모듈 CLAUDE.md 의 마지막 commit
  last_commit=$(git log -1 --format=%H -- "$claude_md" 2>/dev/null || true)
  [ -z "$last_commit" ] && continue

  # 누적 변경 라인 (모듈 경로 기준, last_commit..HEAD)
  lines=$(git diff "${last_commit}..HEAD" --numstat -- "$module_path" 2>/dev/null \
    | awk 'BEGIN{s=0} {if ($1 ~ /^[0-9]+$/) s+=$1; if ($2 ~ /^[0-9]+$/) s+=$2} END{print s+0}')

  # 경과일
  last_ts=$(git log -1 --format=%ct -- "$claude_md" 2>/dev/null || true)
  if [ -n "$last_ts" ]; then
    days=$(( (now_epoch - last_ts) / 86400 ))
  else
    days=0
  fi

  if [ "${lines:-0}" -ge "$threshold_lines" ] || [ "$days" -ge "$threshold_days" ]; then
    # 표시 라벨: feature/home → :feature:home (Android 친화). iOS 의 경우도 동일 표기 유지.
    label=":${module_path//\//:}"
    warnings+=("[decay] $label CLAUDE.md 확인이 필요합니다 (변경 라인 ${lines:-0}, $days 일 경과).")
    warnings+=("        /harness-module-refresh $label  — 코드 변화 자동 점검 (역할/함정/의존)")
    warnings+=("        /harness-module-edit $label    — 5 섹션 직접 선택 수정")
  fi
done <<< "$modules"

if [ ${#warnings[@]:-0} -gt 0 ]; then
  printf '%s\n' "${warnings[@]}" >&2
fi

exit 0
