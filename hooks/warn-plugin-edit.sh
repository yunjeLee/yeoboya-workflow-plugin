#!/bin/bash
# Hook 1: yeoboya-workflow-plugin 내부 파일 수정 시 사용자 확인 요청 (Soft warn / Ask)
# Matcher: PreToolUse / Edit, Write
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Edit / Write 가 아니면 통과
case "$tool_name" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

# 파일 경로가 비어있으면 통과
[ -z "$file_path" ] && exit 0

# Plugin 내부 경로 매칭 (디렉토리명 기반)
case "$file_path" in
  *yeoboya-workflow-plugin/*)
    echo "이 파일은 yeoboya-workflow-plugin 내부 파일입니다: $file_path" >&2
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"plugin 내부 파일 수정 확인 필요"}}'
    exit 0
    ;;
esac

exit 0
