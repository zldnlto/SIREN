---
name: pr-ready
description: Sub-issue 작업 완료 후 Draft PR 본문을 생성한다.
disable-model-invocation: true
argument-hint: "[parent-issue] [sub-issue-1] [sub-issue-2] ..."
---

1. 현재 상태 확인:
   - git status
   - git branch --show-current
   - git diff --stat
   - git log --oneline -5

2. 브랜치 네이밍 검증:
   - 일반: <type>/<이슈번호>-<설명>
   - 실험: exp/<설명>

3. PR 본문 생성:

## Summary

이번 PR에서 무엇을 했는지 요약

## Why

이 변경이 왜 필요한가

## Changes

- 변경 사항 1
- 변경 사항 2

## Validation

- [ ] pytest 또는 compileall
- [ ] flutter analyze
- [ ] docker compose up -d
- [ ] API smoke test
- [ ] CI / Husky 통과

## Screenshots / Logs

해당 없음

## Known Limitations

알려진 한계 또는 다음 단계

## 관련 이슈

Closes #[부모이슈]
Closes #[sub-issue-1]
Closes #[sub-issue-2]

## Checklist

- [ ] Draft PR
- [ ] 모델 가중치 없음
- [ ] secret 없음
- [ ] 컨벤션 준수

4. 규칙:
   - AI / Claude 언급 금지
   - 명시적 요청 없이 PR을 생성하거나 push하지 않는다
   - Draft PR로 먼저 생성한다
