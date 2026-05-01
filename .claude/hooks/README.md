# Hooks 실행 순서

Claude Code 생명주기별 자동 실행 스크립트

## 실행 순서

PreToolUse (Edit/Write 전)

protect-files.sh 민감 파일 수정 차단
audit-risky-change.sh 위험 명령어 감지

PostToolUse (Edit/Write 후) 3. format-edited-file.sh 포맷 자동 적용
UserPromptSubmit (프롬프트 입력 시) 4. inject-issue-context.sh 현재 브랜치/이슈 컨텍스트 주입

## 파일별 역할

| 파일                    | 이벤트           | 역할                                   |
| ----------------------- | ---------------- | -------------------------------------- |
| protect-files.sh        | PreToolUse       | .env, secrets, weights 수정 차단       |
| audit-risky-change.sh   | PreToolUse       | 위험 명령어 패턴 감지                  |
| format-edited-file.sh   | PostToolUse      | black/isort/dart format 자동 실행      |
| inject-issue-context.sh | UserPromptSubmit | git status, 브랜치, 이슈 컨텍스트 주입 |

## 주의사항

- Hook 실패 시 Claude Code 작업이 중단됨
- protect-files.sh, audit-risky-change.sh는 의도적으로 강하게 차단
- format-edited-file.sh 실패는 경고만 출력 (작업 중단 없음)
