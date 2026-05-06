#!/bin/bash
# Hook 2: 하네스 7 개 .md 가 commit/push 대상이면 차단 (Hard block / Deny)
# Matcher: PreToolUse / Bash
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Bash 가 아니면 통과
[ "$tool_name" != "Bash" ] && exit 0

# git commit / git push 가 아니면 통과
case "$command" in
  *"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

# 변경 대상 파일 수집
files=""
case "$command" in
  *"git commit"*)
    files=$(git diff --cached --name-only 2>/dev/null || true)
    ;;
  *"git push"*)
    # upstream 미설정 / 첫 push 코너 케이스 대응
    files=$(git log @{push}..HEAD --name-only 2>/dev/null \
            || git log "origin/$(git rev-parse --abbrev-ref HEAD)..HEAD" --name-only 2>/dev/null \
            || true)
    ;;
esac

# 하네스 7 개 파일 매칭
harness_files=(
  "CLAUDE.md"
  "docs/PRD.md"
  "docs/ADR.md"
  "docs/ARCHITECTURE.md"
  "docs/TESTING.md"
  "docs/CONVENTIONS.md"
  "docs/UI_GUIDE.md"
)

blocked=()
for hf in "${harness_files[@]}"; do
  if echo "$files" | grep -qx "$hf"; then
    blocked+=("$hf")
  fi
done

if [ ${#blocked[@]} -gt 0 ]; then
  {
    echo "다음 파일은 사용자가 IDE 에서 직접 commit/push 합니다 (Claude 자동 commit 차단):"
    printf '  - %s\n' "${blocked[@]}"
    echo ""
    echo "해결:"
    echo "  - staging 에서 제외:  git reset HEAD ${blocked[*]}"
    echo "  - 또는 IDE 에서 검토 후 직접 commit"
  } >&2
  exit 2
fi

exit 0
