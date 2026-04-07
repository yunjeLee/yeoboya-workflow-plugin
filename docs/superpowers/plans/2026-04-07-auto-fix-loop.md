# Auto-Fix Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** CI 실패 시 AI가 에러를 자동 분석·수정·재시도하는 루프를 shared 모듈로 구현하고, `/auto-fix` 단독 스킬과 `/phase` Task별 실행에 통합한다.

**Architecture:** `shared/auto-fix-loop.md`를 핵심 루프 로직으로 만들고, `/auto-fix` 스킬과 `/phase` 스킬이 각각 Read tool로 읽어 따른다. 기존 `shared/prompt-refiner.md` 패턴과 동일한 방식.

**Tech Stack:** Claude Code skills (Markdown), Read tool 참조 패턴

---

### Task 1: shared/auto-fix-loop.md 생성

핵심 루프 로직을 shared 모듈로 작성한다. 플랫폼 자동 감지, 최대 3회 재시도, 성공/실패 리포트를 포함한다.

**Files:**
- Create: `shared/auto-fix-loop.md`

- [ ] **Step 1: 파일 생성**

`shared/auto-fix-loop.md`를 아래 내용으로 작성한다.

```markdown
# Auto-Fix Loop

이 지침을 Read tool로 읽은 스킬은 아래 순서를 따른다.

---

## 플랫폼 감지

프로젝트 루트에서 아래 파일을 스캔해 테스트 명령어를 결정한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
  TEST_CMD=./gradlew test

*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
  TEST_CMD=xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'

둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문 후 결정
```

---

## 루프 실행

아래 루프를 최대 3회 반복한다. (RETRY=0 으로 시작)

### 1. 테스트 실행

Bash tool로 TEST_CMD를 실행한다.

**성공 시 (exit code 0):**
아래 리포트를 출력하고 루프를 종료한다.

```
[Auto-Fix 완료]
- 시도 횟수: {RETRY+1}/3
- 수정한 파일: {수정한 파일 목록. 없으면 "없음"}
- 테스트 결과: PASS
```

**실패 시 (exit code ≠ 0):**
stdout + stderr 전체를 캡처해 다음 단계로 이동한다.

### 2. 에러 분석 및 수정 (실패 시)

캡처한 에러 메시지를 분석한다.

1. 에러가 발생한 파일과 라인을 특정한다.
2. 원인을 판단한다.
3. Read tool로 해당 파일을 읽고 Edit tool로 수정한다.
4. RETRY += 1

**RETRY < 3** → 1번(테스트 실행)으로 돌아간다.

**RETRY ≥ 3** → 아래 실패 리포트를 출력하고 루프를 종료한다.

```
[Auto-Fix 실패]
- 시도 횟수: 3/3
- 마지막 에러: {에러 요약 2-3줄}
- 수정 시도한 파일: {목록}
→ 수동 개입이 필요합니다.
```
```

- [ ] **Step 2: 커밋**

```bash
git add shared/auto-fix-loop.md
git commit -m "feat: add shared auto-fix-loop module"
```

---

### Task 2: skills/auto-fix/SKILL.md 생성

`/auto-fix` 단독 실행 스킬을 작성한다. `shared/auto-fix-loop.md`를 Read하고 따른다.

**Files:**
- Create: `skills/auto-fix/SKILL.md`

- [ ] **Step 1: 파일 생성**

`skills/auto-fix/SKILL.md`를 아래 내용으로 작성한다.

```markdown
---
name: auto-fix
description: "테스트를 실행하고 실패 시 AI가 자동으로 수정·재시도한다. 최대 3회 시도. /auto-fix로 실행하며 플랫폼(Android/iOS)을 자동 감지한다."
---

# Auto-Fix Skill — 자동 교정 루프

테스트를 실행하고 실패 시 AI가 자동으로 원인을 분석해 수정한 뒤 재시도한다.

## 트리거
- `/auto-fix` — 플랫폼 자동 감지 후 루프 실행

---

## Step 1: 루프 실행

`shared/auto-fix-loop.md`를 Read tool로 읽고 지침을 따른다.
```

- [ ] **Step 2: 커밋**

```bash
git add skills/auto-fix/SKILL.md
git commit -m "feat: add /auto-fix skill"
```

---

### Task 3: plugin.json에 /auto-fix 등록

`.claude-plugin/plugin.json`의 `skills` 배열에 `/auto-fix`를 추가한다.

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: plugin.json 수정**

현재 내용:
```json
{
  "skills": [
    { "name": "feature",          "path": "skills/feature/SKILL.md" },
    { "name": "bugfix",           "path": "skills/bugfix/SKILL.md" },
    { "name": "migration",        "path": "skills/migration/SKILL.md" },
    { "name": "new-app",          "path": "skills/new-app/SKILL.md" },
    { "name": "ui-preview-loop",  "path": "skills/ui-preview-loop/SKILL.md" },
    { "name": "phase",            "path": "skills/phase/SKILL.md" }
  ]
}
```

`"phase"` 항목 아래에 다음을 추가한다.

```json
{ "name": "auto-fix", "path": "skills/auto-fix/SKILL.md" }
```

- [ ] **Step 2: 커밋**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: register /auto-fix skill in plugin.json"
```

---

### Task 4: skills/phase/SKILL.md 수정 — Task별 루프 통합

`/phase` 스킬의 Step 3(실행)을 수정해, 각 Task 완료 후 auto-fix 루프를 실행하도록 한다.

**Files:**
- Modify: `skills/phase/SKILL.md`

- [ ] **Step 1: 현재 Step 3 확인**

`skills/phase/SKILL.md`를 Read tool로 읽고 현재 Step 3 내용을 파악한다.

- [ ] **Step 2: Step 3 교체**

현재 Step 3:
```markdown
## Step 3: 실행

`superpowers:executing-plans` 스킬을 호출한다.
- 선택된 Phase 전체(Phase 내 모든 Task)를 하나의 실행 단위로 전달한다.
- 실행 중 실패가 발생하면 사용자에게 실패 내용을 보고하고, 중단할지 계속 진행할지 확인한다.
```

아래 내용으로 교체한다:

```markdown
## Step 3: 실행

선택된 Phase 내 Task를 하나씩 순서대로 실행한다.

각 Task에 대해 아래 순서를 따른다.

### 3-1. Task 실행

`superpowers:executing-plans` 스킬을 호출해 해당 Task를 실행한다.

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
```

- [ ] **Step 3: Step 4 완료 리포트 항목 추가**

현재 완료 안내:
```markdown
완료 후 안내:

```
Phase N 완료. {skill}-plan.md 업데이트됨.
(N은 실제 완료된 Phase 번호로 치환한다)

다음 단계:
  /phase [N+1]   → 다음 Phase 실행 (N+1은 실제 다음 번호로 치환)
  /phase         → 첫 미완료 Phase 자동 실행
```
```

아래 내용으로 교체한다:

```markdown
완료 후 안내:

```
Phase N 완료. {skill}-plan.md 업데이트됨.

## Phase N 완료 리포트
- 성공한 Task: {성공 수}개
- Auto-Fix 성공: {Auto-Fix로 통과한 수}개
- 수동 처리 필요: {실패 기록된 수}개

다음 단계:
  /phase [N+1]   → 다음 Phase 실행 (N+1은 실제 다음 번호로 치환)
  /phase         → 첫 미완료 Phase 자동 실행
```
```

- [ ] **Step 4: 커밋**

```bash
git add skills/phase/SKILL.md
git commit -m "feat: integrate auto-fix loop into /phase per-task execution"
```
