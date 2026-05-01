#!/usr/bin/env bash
# inject-issue-context.sh
# UserPromptSubmit — 현재 브랜치/이슈/git 상태를 컨텍스트로 주입

set -uo pipefail

# Git repo가 아니면 조용히 종료
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
STATUS=$(git status --short 2>/dev/null | head -5 || echo "")
CHANGED_COUNT=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "")

# 브랜치에서 이슈 번호 추출
PARENT_ISSUE=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1 || echo "")

# additionalContext 구성
CONTEXT="## SIREN 작업 컨텍스트
- 브랜치: $BRANCH"

if [[ -n "$PARENT_ISSUE" ]]; then
  CONTEXT="$CONTEXT
- 부모 이슈: #$PARENT_ISSUE"

  # gh CLI가 있으면 이슈 제목 조회
  if command -v gh &>/dev/null; then
    ISSUE_TITLE=$(gh issue view "$PARENT_ISSUE" --json title -q '.title' 2>/dev/null || echo "")
    if [[ -n "$ISSUE_TITLE" ]]; then
      CONTEXT="$CONTEXT
- 이슈 제목: $ISSUE_TITLE"
    fi
  fi
fi

if [[ "$CHANGED_COUNT" -gt 0 ]]; then
  CONTEXT="$CONTEXT
- 변경된 파일: ${CHANGED_COUNT}개"
  if [[ -n "$STATUS" ]]; then
    CONTEXT="$CONTEXT
$STATUS"
  fi
else
  CONTEXT="$CONTEXT
- Git 상태: clean"
fi

if [[ -n "$LAST_COMMIT" ]]; then
  CONTEXT="$CONTEXT
- 최근 커밋: $LAST_COMMIT"
fi

CONTEXT="$CONTEXT
- 워크플로우: Issue → Sub-issue → Commit → Draft PR → Squash Merge"

# 공식 additionalContext JSON 형식으로 출력
printf '%s' "$CONTEXT" | jq -Rs '{"additionalContext": .}'

exit 0