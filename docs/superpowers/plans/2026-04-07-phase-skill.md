# Phase Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/phase [N]` 스킬을 추가하고, 기존 스킬이 계획 수립 후 실행을 사용자에게 위임하도록 수정한다.

**Architecture:** 기존 스킬(`new-app`, `feature`, `migration`)은 `writing-plans` 완료 후 `{skill}-plan.md`를 저장하고 종료한다. `/phase`는 해당 파일을 읽어 `executing-plans`로 단계별 실행하고, 완료된 Phase를 체크리스트에 반영한다.

**Tech Stack:** Markdown skill files, git

---

## Phase 1: skills/phase/SKILL.md 신규 생성

**Files:**
- Create: `skills/phase/SKILL.md`

- [ ] **Step 1: skills/phase/ 디렉토리 생성 및 SKILL.md 작성**

`skills/phase/SKILL.md` 내용:

```markdown
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
먼저 /feature, /new-app, 또는 /migration을 실행해 계획을 작성하세요.
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
- 선택된 Phase의 Task 목록을 전달한다.

---

## Step 4: plan.md 체크리스트 업데이트

Phase 실행 완료 후 plan.md를 업데이트한다.
- 해당 Phase 내 모든 `- [ ]` → `- [x]` 로 변경한다.

완료 후 안내:
```
Phase N 완료. {skill}-plan.md 업데이트됨.

다음 단계:
  /phase N+1   → 다음 Phase 실행
  /phase       → 첫 미완료 Phase 자동 실행
```
```

- [ ] **Step 2: 파일이 올바르게 저장됐는지 확인**

```bash
cat skills/phase/SKILL.md
```

Expected: frontmatter의 `name: phase` 및 전체 내용 출력

- [ ] **Step 3: Commit**

```bash
git add skills/phase/SKILL.md
git commit -m "feat: add /phase skill for step-by-step plan execution"
```

---

## Phase 2: skills/new-app/SKILL.md 수정

**Files:**
- Modify: `skills/new-app/SKILL.md`

- [ ] **Step 1: Step 4 (executing-plans 호출) 제거 후 plan.md 저장 + 안내로 교체**

`## Step 4: 프로젝트 생성 (executing-plans)` 섹션 전체를 아래로 교체:

```markdown
## Step 4: 계획 저장 및 실행 안내

writing-plans 완료 후 계획을 파일로 저장한다.

**파일명 규칙:**
- 기본: `new-app-plan.md`
- `new-app-plan.md`가 이미 존재하면: `new-app-plan-YYYYMMDD.md` (오늘 날짜)

저장 완료 후 아래 메시지를 출력한다:

```
계획이 new-app-plan.md 에 저장됐습니다.

시작하려면:
  /phase 1       → Phase 1부터 실행
  /phase         → 체크리스트 기준 첫 미완료 Phase 실행
```
```

- [ ] **Step 2: 완료 리포트 섹션도 확인 — executing-plans 관련 언급이 있으면 제거**

```bash
grep -n "executing-plans" skills/new-app/SKILL.md
```

Expected: 출력 없음 (제거 완료)

- [ ] **Step 3: Commit**

```bash
git add skills/new-app/SKILL.md
git commit -m "feat: new-app stops at plan.md, delegates execution to /phase"
```

---

## Phase 3: skills/feature/SKILL.md 수정

**Files:**
- Modify: `skills/feature/SKILL.md`

- [ ] **Step 1: Step 5 (executing-plans 호출) 제거 후 plan.md 저장 + 안내로 교체**

`## Step 5: 구현 실행 (executing-plans + Worker 격리)` 섹션 전체를 아래로 교체:

```markdown
## Step 5: 계획 저장 및 실행 안내

writing-plans 완료 후 계획을 파일로 저장한다.

**파일명 규칙:**
- 기본: `feature-plan.md`
- `feature-plan.md`가 이미 존재하면: `feature-plan-YYYYMMDD.md` (오늘 날짜)

저장 완료 후 아래 메시지를 출력한다:

```
계획이 feature-plan.md 에 저장됐습니다.

시작하려면:
  /phase 1       → Phase 1부터 실행
  /phase         → 체크리스트 기준 첫 미완료 Phase 실행
```
```

- [ ] **Step 2: Step 6 (verification-before-completion) 섹션 제거**

Step 6는 `/phase`가 각 Phase 완료 후 처리하므로 feature 스킬에서 제거한다.

```bash
grep -n "verification-before-completion\|executing-plans" skills/feature/SKILL.md
```

Expected: 출력 없음

- [ ] **Step 3: 완료 리포트에서 테스트/검토 결과 항목 제거**

완료 리포트는 plan.md 저장 완료 시점이므로 아래만 남긴다:

```markdown
## 완료 리포트 형식

```
## Feature 완료 리포트
- 플랫폼: Android / iOS
- 기획서: [파일명]
- 변경 모드: 신규 / 수정 대응
- 계획 파일: feature-plan.md
- 구현은 /phase로 단계별 실행
```
```

- [ ] **Step 4: Commit**

```bash
git add skills/feature/SKILL.md
git commit -m "feat: feature stops at plan.md, delegates execution to /phase"
```

---

## Phase 4: skills/migration/SKILL.md 수정

**Files:**
- Modify: `skills/migration/SKILL.md`

- [ ] **Step 1: Step 4 (subagent-driven-development), Step 5 (reviewer), Step 6 (verification) 제거 후 plan.md 저장 + 안내로 교체**

`## Step 4: 병렬 실행 (subagent-driven-development)` 섹션부터 `## 에러 처리` 직전까지를 아래로 교체:

```markdown
## Step 4: 계획 저장 및 실행 안내

writing-plans 완료 후 계획을 파일로 저장한다.

**파일명 규칙:**
- 기본: `migration-plan.md`
- `migration-plan.md`가 이미 존재하면: `migration-plan-YYYYMMDD.md` (오늘 날짜)

저장 완료 후 아래 메시지를 출력한다:

```
계획이 migration-plan.md 에 저장됐습니다.

시작하려면:
  /phase 1       → Phase 1부터 실행
  /phase         → 체크리스트 기준 첫 미완료 Phase 실행
```
```

- [ ] **Step 2: 잔존 참조 확인**

```bash
grep -n "subagent-driven-development\|executing-plans\|verification-before-completion" skills/migration/SKILL.md
```

Expected: 출력 없음

- [ ] **Step 3: 완료 리포트 수정**

```markdown
## 완료 리포트 형식

```
## Migration 완료 리포트
- 플랫폼: Android / iOS
- 마이그레이션 범위: [설명]
- 계획 파일: migration-plan.md
- 구현은 /phase로 단계별 실행
```
```

- [ ] **Step 4: Commit**

```bash
git add skills/migration/SKILL.md
git commit -m "feat: migration stops at plan.md, delegates execution to /phase"
```

---

## Phase 5: plugin.json 업데이트 및 최종 Push

**Files:**
- Modify: `plugin.json`

- [ ] **Step 1: plugin.json에 phase 스킬 등록 확인**

```bash
cat plugin.json
```

`skills` 배열에 `"phase"` 항목이 없으면 추가한다.

- [ ] **Step 2: 전체 변경사항 최종 확인**

```bash
git log --oneline -6
```

Expected: Phase 1~4 커밋 4개 확인

- [ ] **Step 3: Push**

```bash
git push origin master
```
