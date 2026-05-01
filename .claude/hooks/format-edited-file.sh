#!/usr/bin/env bash
# format-edited-file.sh
# 파일 수정 후 포맷 자동 적용

set -uo pipefail

FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

if [[ -z "$FILE" ]]; then
  exit 0
fi

# Python 파일
if echo "$FILE" | grep -qE "\.py$"; then
  if echo "$FILE" | grep -qE "^api/"; then
    if command -v python3 &>/dev/null; then
      cd api
      python3 -m black "$OLDPWD/$FILE" --quiet 2>/dev/null || true
      python3 -m isort "$OLDPWD/$FILE" --quiet 2>/dev/null || true
      cd -
    fi
  fi

  if echo "$FILE" | grep -qE "^vision/"; then
    if command -v python3 &>/dev/null; then
      cd vision
      python3 -m black "$OLDPWD/$FILE" --quiet 2>/dev/null || true
      python3 -m isort "$OLDPWD/$FILE" --quiet 2>/dev/null || true
      cd -
    fi
  fi
fi

# Dart 파일
if echo "$FILE" | grep -qE "\.dart$"; then
  if command -v dart &>/dev/null; then
    dart format "$FILE" --fix 2>/dev/null || true
  fi
fi

# TypeScript / JavaScript 파일
if echo "$FILE" | grep -qE "\.(ts|tsx|js|jsx)$"; then
  if echo "$FILE" | grep -qE "^dashboard/"; then
    if command -v npx &>/dev/null; then
      cd dashboard
      npx prettier --write "$OLDPWD/$FILE" 2>/dev/null || true
      cd -
    fi
  fi
fi

exit 0