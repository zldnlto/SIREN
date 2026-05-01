#!/usr/bin/env bash
# protect-files.sh
# 민감 파일 수정 시도 차단

set -euo pipefail

FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

if [[ -z "$FILE" ]]; then
  exit 0
fi

# 차단 패턴 목록
BLOCKED_PATTERNS=(
  "\.env$"
  "\.env\."
  "secrets/"
  "api/\.env"
  "google-services\.json"
  "GoogleService-Info\.plist"
  "\.pt$"
  "\.onnx$"
  "\.pth$"
  "\.pkl$"
  "vision/data/"
  "vision/datasets/"
  "vision/runs/"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$FILE" | grep -qE "$pattern"; then
    echo "🚫 [protect-files] 차단: $FILE"
    echo "   이 파일은 Claude Code가 수정할 수 없습니다."
    echo "   직접 수정이 필요하면 사람이 진행하세요."
    exit 1
  fi
done

exit 0