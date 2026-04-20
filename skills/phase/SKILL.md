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

1. `{skill}-plan.md` 형식의 파일 목록 수집 (`feature-plan.md`, `bugfix-plan.md` 등)
2. 날짜 suffix가 있는 경우(`feature-plan-20260407.md`) 가장 최신 파일 선택
3. 파일이 없으면 아래 메시지 출력 후 종료:

```
plan.md 파일을 찾을 수 없습니다.
먼저 plan.md를 생성하는 스킬(/feature, /bugfix)을 실행해 계획을 작성하세요.
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
- 수동 처리 필요 Task 목록: []  ← 테스트 실패 후 "다음 Task 진행" 선택한 Task
- 중단 Task 목록: []              ← 테스트 실패 후 "Phase 중단" 선택한 Task
- BASE_SHA: `git rev-parse HEAD` 결과 저장 (Step 4 코드 리뷰의 SHA 범위 산출용)

각 Task에 대해 아래 순서를 따른다.

### 3-1. Task 실행

`writer` 에이전트를 디스패치해 해당 Task의 코드 구현을 수행한다.
writer 에이전트가 사용자에게 TDD 여부를 확인한 후 구현 방식을 선택한다.

### 3-2. 테스트 1 회 실행

Task 실행 완료 후 플랫폼별 테스트 명령을 **1 회** 실행한다 (자동 수정 루프 없음).

- Android: `./gradlew test`
- iOS: `xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'`

**PASS:**
성공 Task 목록에 기록하고 다음 Task 로 진행한다.

**FAIL:**
에러 요약을 사용자에게 보고하고 처리 방향을 묻는다.

```
Task [Task 이름] 테스트 실패
에러: [에러 요약 2-3줄]

처리 방향을 선택하세요:
  1 → 원인 분석 후 수정 (superpowers:systematic-debugging 호출)
  2 → 수동 처리 필요로 기록하고 다음 Task 진행
  3 → Phase 중단 (plan.md 업데이트 안 함)
```

- `1` 응답: `superpowers:systematic-debugging` 스킬을 호출해 원인 분석 후 수정. 재테스트 **1 회**만 실행한다.
  - PASS → 성공 Task 목록에 추가, 다음 Task 진행.
  - FAIL → 더 이상 재시도하지 않는다. `2` (수동 처리 기록 후 다음 Task) 또는 `3` (Phase 중단) 중 선택하도록 다시 묻는다. 이때 `1` 은 선택지에서 제외한다. auto-fix-loop 제거 취지와 정합.
- `2` 응답: 이 Task 를 "수동 처리 필요 Task 목록" 에 기록하고 다음 Task 로 진행.
- `3` 응답: 이 Task 를 "중단 Task 목록" 에 기록하고 실행을 즉시 중단. Step 4 (plan.md 업데이트) 를 건너뛴다.

---

## Step 4: 코드 리뷰

Phase 내 모든 Task 실행 완료 후 `reviewer` 에이전트를 디스패치한다.

### 4-1. SHA 범위 계산

- `BASE_SHA`: Step 3 시작 시 저장한 `git rev-parse HEAD` 결과
- `HEAD_SHA`: 이 Step 진입 시점의 `git rev-parse HEAD` 결과

두 값이 같으면 Phase 내 실제 커밋이 없다는 뜻이므로 리뷰를 생략하고 Step 5 로 진행한다.

### 4-2. reviewer 디스패치

`reviewer` 에이전트를 디스패치한다. 에이전트는 `superpowers:requesting-code-review` 스킬로 `BASE_SHA..HEAD_SHA` 범위의 diff 를 검토하고 결과만 반환한다. 에이전트는 파일을 직접 수정하지 않는다.

### 4-3. 리뷰 결과 처리 (메인 세션)

reviewer 가 반환한 결과는 메인 세션에서 `superpowers:receiving-code-review` 스킬 절차로 처리한다.

1. **READ** — 전체 피드백을 끝까지 읽는다.
2. **UNDERSTAND** — 각 항목을 재구성한다. 불명확하면 먼저 질문한다.
3. **VERIFY** — 코드베이스 실제 상태와 대조한다.
4. **EVALUATE** — 프로젝트 맥락에서 기술적으로 타당한지 판단한다.
5. **CONFIRM** — 수정 항목 목록을 사용자에게 보여주고 승인받는다.
6. **RESPOND** — 기술적 확인 또는 근거 있는 반박.
7. **IMPLEMENT** — 항목 하나씩 테스트 후 진행.

수정 우선순위: Critical (즉시) > Important (다음 작업 전) > Minor (추후 과제).

수정 완료 응답은 "Fixed. [변경 내용]" 형태로 남기고, "You're absolutely right!" 같은 감사 표현은 쓰지 않는다. 코드 자체가 반영 증거다.

---

## Step 5: plan.md 체크리스트 업데이트

리뷰 및 수정 완료 후 plan.md를 업데이트한다.
- 성공 Task: `- [ ]` → `- [x]` 로 변경
- 수동 처리 필요 Task: `- [ ]` 그대로 유지
- 사용자가 3 응답으로 중단한 경우: 이후 Task 전체 `- [ ]` 그대로 유지

완료 후 안내:

```
Phase N 완료. {skill}-plan.md 업데이트됨.
(N은 실제 완료된 Phase 번호로 치환한다)

## Phase N 완료 리포트
- 성공한 Task: {성공 수}개
- 수동 처리 필요: {실패 기록된 수}개

다음 단계:
  /phase [N+1]   → 다음 Phase 실행 (N+1은 실제 다음 번호로 치환)
  /phase         → 첫 미완료 Phase 자동 실행
```
