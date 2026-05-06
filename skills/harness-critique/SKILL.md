---
name: harness-critique
description: "하네스 문서 세트(CLAUDE.md + docs/) 의 품질을 5축(모호성/일관성/완전성/참조 무결성/레포 실상) 으로 검증한다. /harness-critique, 하네스 검증, 하네스 비평, 일관성 점검, 문서 품질 확인 요청 시 반드시 사용한다."
model: opus
---

# Harness-Critique Skill — 하네스 문서 검증

이미 생성된 하네스 문서 세트(7 개) 를 5 축으로 검증한다. `/harness` 또는 `/harness-edit` 안에서도 자동 호출되지만, 이 명령은 **수정 없이 검증만** 따로 부르고 싶을 때 진입점이다 (예: 팀원이 IDE 로 직접 편집한 후 점검).

## 트리거
- `/harness-critique` — 프로젝트 루트에서 실행

---

## Step 1: 하네스 문서 존재 확인

Glob tool 로 아래 파일 존재 여부를 확인한다.

**핵심 6 종**:
- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`
- `docs/TESTING.md`
- `docs/CONVENTIONS.md`

**부가 1 종 (존재 시만)**:
- `docs/UI_GUIDE.md`

### 핵심 6 종 중 하나라도 없으면 종료

```
하네스 문서 세트가 완전하지 않습니다.
먼저 /harness 로 누락된 문서를 생성한 뒤 /harness-critique 를 재실행하세요.

누락된 파일:
  - {실제 누락 파일 경로 나열}
```

---

## Step 2: 검증 모듈 호출

`shared/verify-docs.md` 를 Read tool 로 읽고 5 축 검증 / 심각도 분류 / 사용자 선택 처리를 그대로 따른다.

> 인자 없음. 항상 7 개 전체 (핵심 6 + 부가 1 의 존재분) 검증.

---

## Step 3: 완료 리포트

```
## Harness-Critique 완료 리포트
- 검증 대상: {파일 개수} 개
- 검출 이슈: CRITICAL {n}, WARNING {n}, INFO {n}
- 수정 적용: {n} 건 (verify-docs 반영)
- 남은 이슈: {n} 건

다음 단계:
  변경된 .md 는 사용자가 IDE 에서 직접 검토 후 commit/push 하세요.
  ※ Claude 는 하네스 문서를 직접 commit 하지 않습니다 (Hook 으로 차단됨).
```

> `{파일 개수}` 와 각 수치는 실제 실행 결과로 Claude 가 치환한다.
