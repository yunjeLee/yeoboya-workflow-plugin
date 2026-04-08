---
name: phase
description: "plan.md를 읽어 지정한 Phase를 실행한다. /phase 1, /phase 2처럼 번호를 지정하거나, /phase만 입력하면 첫 번째 미완료 Phase를 자동 실행한다."
---

# Phase Skill — 단계별 실행

`{skill}-plan.md` 파일을 읽어 지정한 Phase를 실행한다.

## 트리거
- `/phase 1` → Phase 1 실행
- `/phase` → 체크리스트 기준 첫 번째 미완료 Phase 자동 실행

---

## Step 1: plan.md 탐색

현재 작업 디렉토리 루트에서 아래 순서로 파일을 탐색한다.

1. `{skill}-plan.md` 형식의 파일 목록 수집 (`feature-plan.md`, `new-app-plan.md`, `migration-plan.md` 등)
2. 날짜 suffix가 있는 경우(`feature-plan-20260407.md`) 가장 최신 파일 선택
3. 파일이 없으면 아래 메시지 출력 후 종료:

```
plan.md 파일을 찾을 수 없습니다.
먼저 plan.md를 생성하는 스킬(/feature, /new-app 등)을 실행해 계획을 작성하세요.
```

---

## Step 2: Phase 결정

**번호 지정 시 (`/phase N`):**
- plan.md에서 `## Phase N:` 섹션을 찾는다.
- 없으면: `"Phase N이 plan.md에 존재하지 않습니다."` 출력 후 종료

**번호 미지정 시 (`/phase`):**
- plan.md 전체를 스캔해 `- [ ]`가 남아있는 첫 번째 Phase를 선택한다.
- 모든 Phase가 `- [x]`이면: `"모든 Phase가 완료됐습니다."` 출력 후 `superpowers:finishing-a-development-branch` 스킬을 호출한다.

---

## Step 3: 실행

선택된 Phase 내 Task를 하나씩 순서대로 실행한다.

Phase 실행 시작 시 아래 목록을 초기화한다:
- 성공 Task 목록: []
- Auto-Fix 성공 Task 목록: []  ← 코드는 성공했으나 auto-fix 루프를 거친 Task
- 수동 처리 필요 Task 목록: []  ← auto-fix 3회 실패 후 y 응답으로 진행한 Task

각 Task에 대해 아래 순서를 따른다.

### 3-1. Task 실행

`writer` 에이전트를 디스패치해 해당 Task의 코드 구현을 수행한다.
writer 에이전트가 사용자에게 TDD 여부를 확인한 후 구현 방식을 선택한다.

### 3-2. Auto-Fix 루프 실행

Task 실행 완료 후 `shared/auto-fix-loop.md`를 Read tool로 읽고 지침을 따른다.

**Auto-Fix 성공 시:**
- 결과를 기록하고 다음 Task로 진행한다.

**Auto-Fix 실패 시 (3회 초과):**
아래 메시지를 출력하고 사용자에게 확인한다.

```
Task [Task 이름] 자동 수정 실패 (3/3 시도).
마지막 에러: [에러 요약]

계속 진행할까요?
  y → 다음 Task로 진행 (이 Task는 수동 처리 필요로 기록)
  n → Phase 실행 중단 (plan.md 업데이트 안 함)
```

- `y` 응답: 이 Task를 "수동 처리 필요"로 기록하고 다음 Task로 진행
- `n` 응답: 실행을 즉시 중단하고 Step 4(plan.md 업데이트)를 건너뜀

---

## Step 4: 코드 리뷰

Phase 내 모든 Task 실행 완료 후 `reviewer` 에이전트를 디스패치한다.

reviewer 에이전트가 `superpowers:requesting-code-review` 스킬을 통해 이번 Phase에서 변경된 코드를 검토한다.
리뷰 결과 수신 후 `superpowers:receiving-code-review` 스킬로 수정 사항을 처리한다.

---

## Step 5: plan.md 체크리스트 업데이트

리뷰 및 수정 완료 후 plan.md를 업데이트한다.
- 성공 Task와 Auto-Fix 성공 Task: `- [ ]` → `- [x]` 로 변경
- 수동 처리 필요 Task: `- [ ]` 그대로 유지
- 사용자가 n 응답으로 중단한 경우: 이후 Task 전체 `- [ ]` 그대로 유지

완료 후 안내:

```
Phase N 완료. {skill}-plan.md 업데이트됨.
(N은 실제 완료된 Phase 번호로 치환한다)

## Phase N 완료 리포트
- 성공한 Task: {성공 수}개
- Auto-Fix 성공: {Auto-Fix로 통과한 수}개
- 수동 처리 필요: {실패 기록된 수}개

다음 단계:
  /phase [N+1]   → 다음 Phase 실행 (N+1은 실제 다음 번호로 치환)
  /phase         → 첫 미완료 Phase 자동 실행
```
