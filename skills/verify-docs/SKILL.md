---
name: verify-docs
description: "하네스 문서 세트(CLAUDE.md + docs/)의 품질을 재검증한다. /onboard 로 만든 문서를 팀원이 직접 수정한 뒤, 모호성 / 규칙 충돌 / 참조 깨짐 / 레포 실상 불일치가 생겼는지 점검한다. /verify-docs, 문서 검증, 재검증, 품질 점검 요청 시 반드시 사용한다."
model: opus
---

# Verify-Docs Skill — 하네스 문서 품질 재검증

`/onboard` 로 생성한 하네스 문서 세트를 팀원이 직접 편집한 이후, 그 결과의
품질을 재점검한다. 모호성 / 규칙 충돌 / 필수 섹션 누락 / 참조 깨짐 / 레포 실제 상태와의 불일치를 한 번에 걸러낸다.

## 트리거
- `/verify-docs` — 프로젝트 루트에서 실행

---

## Step 1: 하네스 문서 존재 확인

아래 파일의 존재 여부를 Glob tool 로 확인한다.

**핵심 문서 (6 종)**:
- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`
- `docs/TESTING.md`
- `docs/CONVENTIONS.md`

**부가 파일** (존재 시만 검증 대상에 포함):
- `docs/UI_GUIDE.md`
- `docs/WORKFLOW.md`

**핵심 문서 6 종 중 하나라도 없으면** 아래 메시지를 출력하고 종료한다:

```
하네스 문서 세트가 완전하지 않습니다.
먼저 /onboard 로 누락된 문서를 생성한 뒤 /verify-docs 를 재실행하세요.

누락된 파일:
  - {실제 누락 파일 경로 나열}
```

---

## Step 2: Self-Critique 로직 호출

`shared/onboard-critique.md` 를 Read tool 로 읽고 **5 축 체크** 를 실행한다.

### scope override (중요)

`onboard-critique.md` 는 "Case 2 에서 이번 onboard 실행으로 새로 생성한 파일만" 검증 대상으로 한정하지만, `/verify-docs` 에서는 이 규칙을 **무시** 한다.

- **검증 대상**: Step 1 에서 확인된 **모든 하네스 문서** (핵심 6 종 + 존재하는 부가 파일)
- 이외 5 축 검사 절차(ambiguity / consistency / completeness / referential integrity / reality-check), 심각도 분류, 출력 포맷, 사용자 선택 후 처리(자동 수정 / 항목별 선택 / 그대로 진행) 로직은 `onboard-critique.md` 를 그대로 따른다.

---

## Step 3: 완료 리포트

```
## Verify-Docs 완료 리포트
- 검증 대상: {파일 개수} 개
- 검출 이슈: CRITICAL {n}, WARNING {n}, INFO {n}
- 수정 적용: {n} 건 (critique 반영)
- 남은 이슈: {n} 건

다음 단계:
  git add -p   → 변경사항 검토 후 commit
```

> `{검증 대상 파일 개수}` 와 각 수치는 실제 실행 결과로 Claude 가 치환한다.
