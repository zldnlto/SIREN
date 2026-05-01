#!/usr/bin/env bash
# format-edited-file.sh
# PostToolUse — 파일 수정 후 포맷 자동 적용

set -uo pipefail

INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')"

if [[ -z "$FILE" ]]; then
  exit 0
fi

# 포맷 제외 대상
EXCLUDE_PATTERNS=(
  "pubspec\.lock"
  "migrations/"
  "alembic/"
  "\.g\.dart$"
  "\.freezed\.dart$"
  "generated/"
  "vision/data/"
  "vision/runs/"
)

for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  if echo "$FILE" | grep -qE "$pattern"; then
    exit 0
  fi
done

# Python
if echo "$FILE" | grep -qE "\.py$"; then
  if command -v ruff &>/dev/null; then
    ruff format "$FILE" --quiet 2>/dev/null || true
  elif command -v python3 &>/dev/null; then
    python3 -m black "$FILE" --quiet 2>/dev/null || true
    python3 -m isort "$FILE" --quiet 2>/dev/null || true
  fi
fi

# Dart
if echo "$FILE" | grep -qE "\.dart$"; then
  if command -v dart &>/dev/null; then
    dart format "$FILE" --fix 2>/dev/null || true
  fi
fi

# JSON / YAML / Markdown
if echo "$FILE" | grep -qE "\.(json|yaml|yml|md)$"; then
  if command -v prettier &>/dev/null; then
    prettier --write "$FILE" 2>/dev/null || true
  fi
fi

# TypeScript / JavaScript
if echo "$FILE" | grep -qE "\.(ts|tsx|js|jsx)$"; then
  if echo "$FILE" | grep -qE "^dashboard/"; then
    if command -v npx &>/dev/null; then
      cd dashboard && npx prettier --write "$OLDPWD/$FILE" 2>/dev/null || true && cd -
    fi
  fi
fi

# SQL (선택적)
if echo "$FILE" | grep -qE "\.sql$"; then
  if command -v sqlfluff &>/dev/null; then
    sqlfluff format "$FILE" 2>/dev/null || true
  fi
fi

# 포맷 실패해도 작업 중단 없음
exit 0