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
- 모든 Phase가 `- [x]`이면: `"모든 Phase가 완료됐습니다."` 출력 후 종료

---

## Step 3: 실행

`superpowers:executing-plans` 스킬을 호출한다.
- 선택된 Phase 전체(Phase 내 모든 Task)를 하나의 실행 단위로 전달한다.
- 실행 중 실패가 발생하면 사용자에게 실패 내용을 보고하고, 중단할지 계속 진행할지 확인한다.

---

## Step 4: plan.md 체크리스트 업데이트

Phase 실행 완료 후 plan.md를 업데이트한다.
- 해당 Phase 내 모든 `- [ ]` → `- [x]` 로 변경한다.

완료 후 안내:

```
Phase N 완료. {skill}-plan.md 업데이트됨.
(N은 실제 완료된 Phase 번호로 치환한다)

다음 단계:
  /phase [N+1]   → 다음 Phase 실행 (N+1은 실제 다음 번호로 치환)
  /phase         → 첫 미완료 Phase 자동 실행
```
