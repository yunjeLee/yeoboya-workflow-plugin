---
name: migration
description: "기획서(PDF) 또는 텍스트 설명을 기반으로 코드 마이그레이션을 수행한다. /migration, 라이브러리 전환, 아키텍처 변경, 코드 이전, 마이그레이션 요청 시 반드시 사용한다. PDF 없이 마이그레이션 목표를 말로 설명해도 동일하게 동작한다."
---

# Migration Skill — 마이그레이션

기획서(PDF) 또는 텍스트 설명을 기반으로 마이그레이션을 수행한다.

## 트리거
- `/migration 기획서.pdf` — PDF 기획서로 시작
- `/migration [마이그레이션 목표 설명]` — 텍스트로 직접 설명

---

## 공통 지침 참조
- **가장 먼저**: `shared/workflow.md`를 Read tool로 읽고 **하네스 문서 부재 감지** 섹션을 실행한다. 응답에 따라 진행 여부를 결정한다.
- 시작 시: `shared/prompt-refiner.md`를 Read tool로 읽고 지침을 따른다.
- UI 작업 감지 시: `shared/ui-review.md`를 Read tool로 읽고 지침을 따른다.

---

## Step 0: 작업 격리 (선택)

마이그레이션은 영향 범위가 넓으므로 브랜치 격리를 권장한다.
`superpowers:using-git-worktrees` 스킬을 호출한다.

---

## Step 1: 플랫폼 자동 감지

`shared/workflow.md`를 Read tool로 읽고 **플랫폼 자동 감지** 섹션의 지침을 따른다.

---

## Step 2: 현재 코드베이스 분석 (brainstorming)

`superpowers:brainstorming`을 호출하여 아래 항목을 분석한다.
- 영향받는 파일 목록
- 의존성 관계 (명시적 + 암묵적)
- 위험 파일 여부 (외부 의존, 공유 상태, 하드코딩, 직접 참조 등)
- 마이그레이션 위험도 (높음 / 보통 / 낮음)

분석 결과를 출력한 후 진행 여부를 확인한다.
- 사용자가 "예"를 선택하면 Step 3으로 진행한다.
- 사용자가 "아니오"를 선택하면 마이그레이션 범위 재조정 후 Step 2를 반복한다.

---

## Step 3: 마이그레이션 계획 작성 (writing-plans)

`superpowers:writing-plans` 스킬을 호출한다.
- 마이그레이션을 독립 가능한 단위로 분리한다.
- 각 단위가 완료 후 빌드 가능한 상태를 유지하도록 순서를 설계한다.

완료 후 `shared/workflow.md`를 Read tool로 읽고 **계획 저장 및 실행 안내** 섹션의 지침을 따른다.

---

## 완료 리포트 형식

```
## Migration 완료 리포트
- 플랫폼: Android / iOS
- 마이그레이션 범위: [설명]
- 계획 파일: migration-plan.md
- 구현은 /phase로 단계별 실행
```
