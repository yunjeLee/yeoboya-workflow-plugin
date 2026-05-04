---
name: harness
description: "프로젝트의 하네스 문서 세트(CLAUDE.md + docs/) 를 생성하거나 누락된 파일만 보완한다. /harness, 하네스 생성, 하네스 보완, harness 만들기, claude code 처음 연결 요청 시 반드시 사용한다."
model: opus
---

# Harness Skill — 하네스 문서 생성/보완

Claude Code 와 프로젝트를 하네스 기법으로 연결한다. 핵심 6 종 + 부가 2 종 의 하네스 문서가 모두 부재(Case 1) 또는 일부 부재(Case 2) 일 때 누락된 파일만 생성한다. 이미 모두 존재하면 다른 명령으로 안내 후 종료한다.

## 트리거
- `/harness` — 프로젝트 루트에서 실행

---

## Step 1: 플랫폼 자동 감지

`shared/workflow.md` 를 Read tool 로 읽고 **플랫폼 자동 감지** 섹션 지침을 따른다.

> 주의: **하네스 문서 부재 감지** 섹션은 이 스킬에서 건너뛴다 (순환 방지).

---

## Step 2: 하네스 8 개 파일 존재 확인

Glob tool 로 아래 파일 존재 여부를 확인한다.

**핵심 6 종**:
- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`
- `docs/TESTING.md`
- `docs/CONVENTIONS.md`

**부가 2 종**:
- `docs/UI_GUIDE.md`
- `docs/WORKFLOW.md`

---

## Step 3: 분기

| 상태 | 분기 |
|------|------|
| 핵심 6 종 모두 존재 + 부가 모두 존재 | **종료 안내** (아래 메시지 출력 후 종료) |
| 핵심 6 종 모두 부재 | **Case 1** — 8 개 모듈 모두 실행 |
| 핵심 6 종 일부 부재 | **Case 2** — 부재 파일에 해당하는 모듈만 실행. 기존 파일은 절대 수정하지 않는다. |

> 부가 2 종은 Case 판정에 영향 없음. UI_GUIDE 는 ui-guide 모듈 내부 분기에서 [y/N] 로 결정. WORKFLOW 는 부재면 모듈 실행에 포함.

### 종료 안내 (모두 존재)

```
하네스 문서가 이미 모두 존재합니다.
  수정: /harness-edit {파일명}      (예: /harness-edit prd)
  검증: /harness-critique
  브리핑: /onboard
  모듈 맵: /harness-map               (모듈 단위 CLAUDE.md + 인덱스 생성)
```

---

## Step 4: 모듈 실행 (Case 1 / Case 2 공통, Phase 분리)

### Phase 1 — 자동 스캔 (질문 0 개)

실행 대상 모듈들의 사전 스캔을 모두 끝낸다.

- `shared/harness/architecture.md`, `shared/harness/workflow.md` 의 콘텐츠를 완성한다 (자동 100%).
- 대화형 모듈(prd / adr / ui-guide / testing / conventions / claude-md) 들의 사전 스캔 결과를 요약 출력한다.
- **이 단계에서는 사용자에게 어떤 질문도 하지 않는다.**

### Phase 2 — 대화형 질문 (순차 1 개씩)

실행 대상 중 대화형 모듈을 아래 순서로 진행한다. 각 모듈 안에서도 질문을 1 개씩 순차로 받는다.

1. `shared/harness/prd.md` (5 개 질문)
2. `shared/harness/adr.md` (카테고리당 3 개 × 6 카테고리)
3. `shared/harness/ui-guide.md` (조건부: 감지 성공 시 2 개, 실패 시 [y/N] 1 개)
4. `shared/harness/testing.md` (4 개)
5. `shared/harness/conventions.md` (6 개)
6. `shared/harness/claude-md.md` (CRITICAL / 피해야 할 것 / 응답 규칙 = 3 개)

> 사용자 답변에 여러 질문의 답이 섞여 들어와도 **현재 질문의 답만 취한다.** 나머지는 해당 차례에 다시 묻는다.

### Phase 3 — 파일 저장

아래 순서로 파일을 저장한다. CLAUDE.md 가 docs/ 를 `@` 로 참조하므로 docs/ 전체를 먼저 저장하고 CLAUDE.md 를 마지막에 저장한다.

1. `docs/PRD.md`
2. `docs/ARCHITECTURE.md`
3. `docs/ADR.md`
4. `docs/UI_GUIDE.md` (감지 결과에 따라 생략 가능)
5. `docs/TESTING.md`
6. `docs/CONVENTIONS.md`
7. `docs/WORKFLOW.md`
8. `CLAUDE.md`

> Case 2 에서는 부재 파일만 저장. 이미 존재하는 파일은 절대 덮어쓰지 않는다.

---

## Step 5: 검증 (Self-Critique)

`shared/verify-docs.md` 를 Read tool 로 읽고 5 축 검증 / 심각도 분류 / 사용자 선택 처리를 그대로 따른다.

> 검증 대상은 항상 8 개 전체. 인자 없음. Case 2 라도 "기존 파일 + 새로 생성한 파일" 모두 검증한다 (cross-file 일관성 보장).

---

## Step 6: 완료 리포트

```
## Harness 완료 리포트
- 플랫폼: {Android / iOS}
- 모드: {Case 1 (전체 생성) / Case 2 (보완 — 부재 파일만)}
- 생성 파일: {목록}   (verify-docs 반영 파일은 옆에 (critique 반영) 표기)
- 스킵 파일 (이미 존재): {목록}    (Case 2 만 해당)
- Verify-Docs: 통과 / 남은 이슈 {n} 건

다음 단계:
  사용자가 IDE 에서 검토 후 직접 commit/push 하세요.
  ※ Claude 는 하네스 문서를 직접 commit 하지 않습니다 (Hook 으로 차단됨).

이후 /feature, /bugfix 등을 실행하면 자동으로 하네스 가드레일이 적용됩니다.
```

> `{생성 파일 목록}` 은 런타임에 실제 생성 파일 경로들로 Claude 가 치환해 출력한다.
