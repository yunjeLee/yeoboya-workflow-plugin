# Phase Skill 설계 문서

**날짜:** 2026-04-07  
**작성자:** yunjelly

---

## 개요

기존 스킬(`new-app`, `feature`, `bugfix`, `migration`)이 계획 수립까지만 담당하고, 실제 구현은 사용자가 `/phase [번호]`로 단계별로 직접 트리거하는 구조로 전환한다.

---

## plan.md 표준 형식

파일명: `{skill}-plan.md` (충돌 시 `{skill}-plan-YYYYMMDD.md`)  
저장 위치: 현재 작업 디렉토리 루트  
`/phase`는 항상 가장 최신 파일을 자동으로 읽는다.

```markdown
# Plan: [작업 제목]

## Phase 1: [제목]
- [ ] Task 1-1
- [ ] Task 1-2

## Phase 2: [제목]
- [ ] Task 2-1
- [ ] Task 2-2

## Phase 3: [제목]
- [ ] Task 3-1
```

**규칙:**
- Phase 번호는 `## Phase N:` 형식, 양의 정수만 허용 (소수점, A/B/C 불가)
- 각 Phase 안에 `- [ ]` 체크리스트 필수
- 완료된 항목은 `- [x]`로 업데이트

---

## 기존 스킬 수정 (new-app, feature, bugfix, migration 공통)

### 제거
- `superpowers:executing-plans` 호출 단계 전체 제거

### 추가 (writing-plans 완료 직후)

1. `{skill}-plan.md` 저장 (충돌 시 날짜 suffix)
2. 사용자 안내 메시지 출력:

```
계획이 {skill}-plan.md 에 저장됐습니다.

시작하려면:
  /phase 1       → Phase 1부터 실행
  /phase         → 체크리스트 기준 첫 미완료 Phase 실행
```

---

## skills/phase/SKILL.md 설계

### 트리거
- `/phase 1` → Phase 1 실행
- `/phase` → 첫 번째 미완료 Phase 자동 실행

### 동작 흐름

**1. plan.md 탐색**
- `{skill}-plan.md` 또는 `{skill}-plan-YYYYMMDD.md` 중 가장 최신 파일 선택
- 없으면 오류 메시지 출력 후 종료:
  ```
  plan.md 파일을 찾을 수 없습니다. 먼저 /feature 또는 /new-app을 실행하세요.
  ```

**2. Phase 결정**
- 번호 있음 → 해당 Phase 읽기
- 번호 없음 → 체크리스트 스캔 후 첫 번째 `- [ ]` Phase 선택
- 모두 완료된 경우 → `"모든 Phase가 완료됐습니다."` 출력 후 종료

**3. 실행**
- `superpowers:executing-plans` 스킬 호출
- 해당 Phase의 Task 목록 전달

**4. 완료 후 plan.md 업데이트**
- 해당 Phase의 `- [ ]` → `- [x]` 로 변경
- 다음 미완료 Phase 안내:
  ```
  Phase N 완료. 다음: /phase N+1 또는 /phase
  ```

---

## 영향 범위

| 파일 | 변경 유형 |
|------|-----------|
| `skills/phase/SKILL.md` | 신규 생성 |
| `skills/new-app/SKILL.md` | executing-plans 제거 + plan.md 안내 추가 |
| `skills/feature/SKILL.md` | executing-plans 제거 + plan.md 안내 추가 |
| `skills/bugfix/SKILL.md` | executing-plans 제거 + plan.md 안내 추가 |
| `skills/migration/SKILL.md` | executing-plans 제거 + plan.md 안내 추가 |
