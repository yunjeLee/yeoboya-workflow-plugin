---
name: harness-edit
description: "이미 생성된 하네스 문서(CLAUDE.md, docs/*.md) 의 특정 섹션을 대화형으로 수정한다. /harness-edit prd, /harness-edit adr 등 8 개 모듈명을 인자로 받는다. 인자 누락 시 모듈 목록을 표시한다. 하네스 수정, 섹션 수정, 일부 다시 작성 요청 시 사용한다."
model: opus
---

# Harness-Edit Skill — 섹션 선택형 수정

이미 생성된 하네스 문서의 특정 섹션만 다시 작성한다. 다른 섹션은 절대 건드리지 않는다.

## 트리거
- `/harness-edit {name}` — `name`: `claude-md` / `prd` / `adr` / `architecture` / `testing` / `conventions` / `ui-guide` / `workflow` 중 하나
- `/harness-edit` (인자 없이) — 8 개 모듈 목록 표시 후 사용자 선택

---

## Step 1: 인자 검증

### 인자 누락 시

```
수정할 모듈을 선택하세요:
  1) claude-md     (CLAUDE.md)
  2) prd           (docs/PRD.md)
  3) adr           (docs/ADR.md)
  4) architecture  (docs/ARCHITECTURE.md)
  5) testing       (docs/TESTING.md)
  6) conventions   (docs/CONVENTIONS.md)
  7) ui-guide      (docs/UI_GUIDE.md)
  8) workflow      (docs/WORKFLOW.md)

번호 입력 또는 모듈명:
```

### 인자가 8 개 중 하나가 아닐 때

다음 메시지 출력 후 위 목록을 다시 표시한다:

```
'{입력값}' 은 유효한 모듈명이 아닙니다. 8 개 중 하나를 선택해주세요.
```

---

## Step 2: 대상 파일 존재 확인

선택된 모듈(`shared/harness/{name}.md`) 의 "대상 파일" 경로를 확인한다 (예: `name=prd` → `docs/PRD.md`).

대상 파일이 부재하면 다음 메시지 출력 후 종료:

```
{파일경로} 가 존재하지 않습니다.
먼저 /harness 를 실행해 누락된 하네스 문서를 생성하세요.
```

---

## Step 3: 모듈 Read + 섹션 목록 표시

`shared/harness/{name}.md` 를 Read tool 로 읽고 "섹션 목록" 표를 사용자에게 그대로 출력한다.

```
[수정할 섹션을 선택하세요]

shared/harness/{name}.md 의 섹션 목록:
{모듈의 "섹션 목록" 표 그대로}

다중 선택 가능 (콤마 구분, 예: 1, 3, 5):
```

---

## Step 4: 선택된 섹션 실행

선택된 섹션 ID 들에 대해 모듈의 "섹션별 생성 로직" 을 1 개씩 순차로 실행한다.

- 사전 스캔이 필요한 섹션은 모듈 정의에 따라 스캔 실행 후 결과를 사용자에게 요약 표시.
- 대화형 섹션은 질문을 1 개씩 받는다. 사용자 답변에 여러 질문의 답이 섞여 들어와도 **현재 질문의 답만 취한다.**
- 자동/정적 섹션은 모듈 로직 그대로 처리.

---

## Step 5: 부분 수정 (Edit 도구)

대상 파일을 Read 로 읽은 뒤, Edit 도구로 H2 (또는 ADR 모듈의 경우 H3) 블록 단위로 교체한다.

### 매칭 단위

- 선택된 섹션 ID 의 시작 헤더(`## ...` 또는 ADR 의 경우 `### ...`) 부터 다음 동급 헤더 (또는 파일 끝) 직전까지를 한 블록으로 본다.
- 새 내용으로 그 블록을 교체.
- **다른 섹션은 절대 수정하지 않는다.**

### 모듈 표준 구조의 예외 (adr.md)

`adr.md` 의 ADR-001 ~ ADR-006 은 H3 이지만 ADR 모듈 안에서 부분 수정의 자연스러운 단위라 H3 도 섹션 ID 로 인정한다.

---

## Step 6: 검증 (Self-Critique)

`shared/verify-docs.md` 를 Read tool 로 읽고 5 축 검증을 실행한다.

> 검증 대상은 인자 없음 = 항상 8 개 전체. 단일 파일 수정이라도 cross-file 일관성을 보장하기 위해 8 개 모두 검사.

---

## Step 7: 완료 리포트

```
## Harness-Edit 완료 리포트
- 대상 모듈: {name}
- 대상 파일: {경로}
- 수정한 섹션: {섹션 ID 와 헤더 목록}
- Verify-Docs: 통과 / 남은 이슈 {n} 건  (verify-docs 반영 파일은 옆에 (critique 반영) 표기)

다음 단계:
  사용자가 IDE 에서 검토 후 직접 commit/push 하세요.
  ※ Claude 는 하네스 문서를 직접 commit 하지 않습니다 (Hook 으로 차단됨).
```
