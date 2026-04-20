# 공통 워크플로우

feature, bugfix 스킬에서 공통으로 사용하는 흐름이다.
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


---

## 계획 저장 및 실행 안내

`superpowers:writing-plans` 완료 후 계획을 파일로 저장한다.

**파일명 규칙:**
- 기본: `{skill}-plan.md` (예: `feature-plan.md`)
- 이미 존재하면: `{skill}-plan-YYYYMMDD.md` (오늘 날짜)

저장 완료 후 아래 메시지를 출력한다:

```
계획이 {skill}-plan.md 에 저장됐습니다.

시작하려면:
  /phase 1       → Phase 1부터 실행
  /phase         → 체크리스트 기준 첫 미완료 Phase 실행
```

## 하네스 문서 부재 감지

**이 섹션은 `/feature`, `/bugfix` 스킬 진입 초반에 실행된다. `/onboard` 는 이 섹션을 건너뛴다 (순환 방지).**

### 검사 대상 — 핵심 문서 세트 (4 종)

프로젝트 루트에 아래 파일이 존재하는지 확인한다:
- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`

### 분기

**A. 핵심 문서가 전혀 없음 (0 개)**

아래 메시지를 출력한다:

```
이 프로젝트에 하네스 문서 세트가 없습니다.
/onboard 를 먼저 실행하면 Claude Code 가 프로젝트를 더 정확하게 이해하고
아키텍처/결정 이력을 자동으로 지킵니다.

지금 /onboard 를 실행하시겠어요? [Y/n]
```

- `Y` (기본) → `skills/onboard/SKILL.md` 를 Read tool 로 읽고 지침을 따른 뒤, 완료되면 원래 스킬의 다음 단계로 이어서 진행한다
- `n` → 경고 한 줄 남기고 원래 스킬 계속 진행

**B. 일부만 있음 (1~3 개)**

```
다음 파일이 없습니다: [여기에 실제 누락 파일 경로를 쉼표로 나열]
하네스 가드레일이 부분만 적용됩니다.
그래도 계속 진행할까요? [y/N]
```

- `y` → 계속 진행
- `N` (기본) → A 와 동일하게 `skills/onboard/SKILL.md` 를 Read 한 뒤 원래 스킬의 다음 단계로 진행한다

**C. 전부 있음 (4 개)**

조용히 통과. 정상 진입.
