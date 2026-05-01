#!/usr/bin/env bash
# protect-files.sh
# PreToolUse — Edit|Write 전 민감 파일 수정 차단

set -euo pipefail

INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')"

if [[ -z "$FILE" ]]; then
  exit 0
fi

# Read도 차단할 파일 (settings.json deny와 중복 보호)
HARD_BLOCK=(
  "\.env$"
  "\.env\."
  "secrets/"
  "\.pem$"
  "\.key$"
  "\.jks$"
  "\.keystore$"
  "google-services\.json"
  "GoogleService-Info\.plist"
)

# 수정만 차단할 파일
SOFT_BLOCK=(
  "\.pt$"
  "\.onnx$"
  "\.pth$"
  "\.pkl$"
  "\.joblib$"
  "\.safetensors$"
  "vision/data/"
  "vision/datasets/"
  "vision/runs/"
  "vision/weights/"
  "vision/checkpoints/"
)

for pattern in "${HARD_BLOCK[@]}"; do
  if echo "$FILE" | grep -qE "$pattern"; then
    echo "🚫 [protect-files] 차단: $FILE" >&2
    echo "   secrets / credentials 파일은 수정할 수 없습니다." >&2
    exit 2
  fi
done

for pattern in "${SOFT_BLOCK[@]}"; do
  if echo "$FILE" | grep -qE "$pattern"; then
    echo "🚫 [protect-files] 차단: $FILE" >&2
    echo "   모델 가중치 / 데이터셋 파일은 커밋하거나 수정할 수 없습니다." >&2
    exit 2
  fi
done

exit 0