# 공통 워크플로우

feature, migration, new-app 스킬에서 공통으로 사용하는 흐름이다.
각 스킬은 필요한 섹션을 Read tool로 읽고 지침을 따른다.

---

## 플랫폼 자동 감지

프로젝트 루트에서 아래 파일을 스캔한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문
```

감지된 플랫폼을 이후 모든 단계에서 사용한다.

> new-app은 신규 프로젝트이므로 이 섹션을 건너뛰고 플랫폼 선택을 직접 받는다.

---

## 계획 저장 및 실행 안내

`superpowers:writing-plans` 완료 후 계획을 파일로 저장한다.

**파일명 규칙:**
- 기본: `{skill}-plan.md` (예: `feature-plan.md`, `migration-plan.md`, `new-app-plan.md`)
- 이미 존재하면: `{skill}-plan-YYYYMMDD.md` (오늘 날짜)

저장 완료 후 아래 메시지를 출력한다:

```
계획이 {skill}-plan.md 에 저장됐습니다.

시작하려면:
  /phase 1       → Phase 1부터 실행
  /phase         → 체크리스트 기준 첫 미완료 Phase 실행
```
