#!/usr/bin/env bash
# inject-issue-context.sh
# 현재 브랜치, 이슈, git 상태를 컨텍스트로 주입

set -uo pipefail

# 현재 브랜치
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# git status 요약
STATUS=$(git status --short 2>/dev/null | head -10 || echo "")

# 최근 커밋
LAST_COMMIT=$(git log --oneline -3 2>/dev/null || echo "")

# 이슈 번호 추출 (브랜치명에서)
ISSUE_NUMBER=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1 || echo "")

# 컨텍스트 출력 (Claude Code가 읽음)
echo "---"
echo "## 현재 작업 컨텍스트"
echo ""
echo "브랜치: $BRANCH"

if [[ -n "$ISSUE_NUMBER" ]]; then
  echo "이슈 번호: #$ISSUE_NUMBER"

  # gh CLI가 있으면 이슈 제목 조회
  if command -v gh &>/dev/null; then
    ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title -q '.title' 2>/dev/null || echo "")
    if [[ -n "$ISSUE_TITLE" ]]; then
      echo "이슈 제목: $ISSUE_TITLE"
    fi
  fi
fi

if [[ -n "$STATUS" ]]; then
  echo ""
  echo "변경된 파일:"
  echo "$STATUS"
fi

if [[ -n "$LAST_COMMIT" ]]; then
  echo ""
  echo "최근 커밋:"
  echo "$LAST_COMMIT"
fi

echo "---"

exit 0