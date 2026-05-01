#!/usr/bin/env bash
# audit-risky-change.sh
# PreToolUse — Bash 전 위험 명령어 감지

set -euo pipefail

INPUT="$(cat)"
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/commands.jsonl"

# 등급 1 — 즉시 차단 (exit 2)
BLOCKING_PATTERNS=(
  "git push --force"
  "git push -f "
  "git reset --hard"
  "git clean -fdx"
  "git checkout -- \."
  "docker compose down -v"
  "docker volume rm"
  "docker system prune"
  "rm -rf data"
  "rm -rf datasets"
  "rm -rf runs"
  "rm -rf weights"
  "rm -rf checkpoints"
  "find data.*-delete"
  "find datasets.*-delete"
  "DROP DATABASE"
  "DROP TABLE"
  "alembic downgrade"
  "curl.*\|.*sh"
  "wget.*\|.*sh"
  "bash.*<.*curl"
  "bash.*<.*wget"
  "rm -rf /"
  "chmod 777"
)

# 등급 2 — 감사 로그만 (exit 0)
AUDIT_PATTERNS=(
  "git commit"
  "gh pr create"
  "pytest"
  "flutter test"
  "flutter analyze"
  "docker compose up"
  "docker compose down$"
  "alembic upgrade"
)

# 차단 검사
for pattern in "${BLOCKING_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "🚫 [audit-risky-change] 위험 명령어 차단: $pattern" >&2
    echo "   명령어: $COMMAND" >&2
    echo "   이 작업은 사람이 직접 확인 후 실행해야 합니다." >&2

    echo "{\"timestamp\":\"$(date -u +%FT%TZ)\",\"level\":\"BLOCKED\",\"pattern\":\"$pattern\",\"command\":\"$COMMAND\"}" >> "$LOG_FILE"
    exit 2
  fi
done

# 감사 로그만 기록
for pattern in "${AUDIT_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "{\"timestamp\":\"$(date -u +%FT%TZ)\",\"level\":\"AUDIT\",\"pattern\":\"$pattern\",\"command\":\"$COMMAND\"}" >> "$LOG_FILE"
    exit 0
  fi
done

exit 0