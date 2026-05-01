#!/usr/bin/env bash
# audit-risky-change.sh
# 위험 명령어 패턴 감지

set -euo pipefail

COMMAND="${CLAUDE_TOOL_INPUT_COMMAND:-}"

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# 위험 명령어 패턴
RISKY_PATTERNS=(
  "rm -rf"
  "git push --force"
  "docker volume rm"
  "docker system prune"
  "curl.*\| *sh"
  "wget.*\| *sh"
  "DROP TABLE"
  "TRUNCATE"
  "chmod 777"
  "> /dev/sda"
)

for pattern in "${RISKY_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "⚠️  [audit-risky-change] 위험 명령어 감지: $pattern"
    echo "   명령어: $COMMAND"
    echo "   이 작업은 사람이 직접 확인 후 실행해야 합니다."
    exit 1
  fi
done

exit 0