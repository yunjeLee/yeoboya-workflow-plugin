# yeoboya-workflow-plugin

앱팀 공통 개발 워크플로우 플러그인 (Android / iOS)

Claude Code를 처음 쓰는 팀원도 명령어 한 줄로 기획 → 설계 → 구현 → 검증까지 표준 흐름을 따를 수 있습니다.

---

## 전체 플로우

### feature / migration / new-app

```
상황에 맞는 스킬 실행
  /feature, /migration, /new-app

         ↓

[선택] 브랜치 격리
  using-git-worktrees

         ↓

플랫폼 자동 감지 (Android / iOS)
요구사항 / 코드베이스 분석 (brainstorming)
구현 계획 작성 → *-plan.md 저장

         ↓  context clear 후

/phase   ← plan.md 보고 단계별 실행

         ↓

각 Task마다
  └─ [subagent] writer  ← TDD 또는 executing-plans 선택 후 구현
  └─ auto-fix 루프      ← 테스트 실패 시 최대 3회 자동 수정

         ↓

Phase 전체 완료 후
  └─ [subagent] reviewer  ← 변경된 코드 전체 리뷰
  └─ receiving-code-review ← 피드백 수정 적용

         ↓

Task 성공 → plan.md 체크리스트 업데이트
Task 실패 → 사용자 확인 후 계속 or 중단
```

### bugfix

```
/bugfix [버그 설명 / 에러 로그 / 스크린샷]

         ↓

[선택] 브랜치 격리
  using-git-worktrees

         ↓

버그 유형 분류
  로직/크래시 버그          UI 버그
       ↓                      ↓
  systematic-debugging    영향 컴포넌트 특정
       ↓                      ↓
  복잡도 판단             스냅샷 테스트로 재현
  단순(1~2파일) → 바로 수정   ↓
  복잡(3+파일) → writing-plans 수정 후 시각적 검증
       ↓                      ↓
  TDD로 재현 후 수정      verification-before-completion
       ↓
  verification-before-completion
```

---

## 스킬 목록

| 명령어 | 설명 | 상세 |
|--------|------|------|
| `/feature` | 기획서(PDF) 또는 설명으로 기능 개발 | [SKILL.md](skills/feature/SKILL.md) |
| `/bugfix` | 버그 설명, 에러 로그, 스크린샷으로 버그 수정 | [SKILL.md](skills/bugfix/SKILL.md) |
| `/migration` | 라이브러리 전환, 아키텍처 변경 등 마이그레이션 | [SKILL.md](skills/migration/SKILL.md) |
| `/new-app` | 새 Android / iOS 앱 프로젝트 스캐폴딩 | [SKILL.md](skills/new-app/SKILL.md) |
| `/ui-preview-loop` | 스크린샷 기반 UI 피드백 루프 | [SKILL.md](skills/ui-preview-loop/SKILL.md) |
| `/phase` | 작성된 plan.md를 Phase 단위로 실행 | [SKILL.md](skills/phase/SKILL.md) |
| `/auto-fix` | 테스트 실행 후 실패 시 자동 수정 (최대 3회) | [SKILL.md](skills/auto-fix/SKILL.md) |

---

## 설치

```bash
git clone https://github.com/yeoboya/yeoboya-workflow-plugin
```

> **주의:** 이 플러그인은 `superpowers` 플러그인에 의존합니다.  
> Claude Code 플러그인 매니저가 자동으로 설치하지 않는 경우 별도로 설치하세요.

---

## 자주 쓰는 시나리오

### 기획서를 받았을 때

```
/feature 기획서.pdf
→ brainstorming → feature-plan.md 생성
→ /phase 1
→ /phase 2
→ ...
```

### 버그 신고를 받았을 때

```
/bugfix 로그아웃 시 크래시 납니다
또는
/bugfix java.lang.NullPointerException at UserRepository.kt:42
→ 원인 분석 → 복잡도 판단 → 수정 → 검증
```

### 라이브러리를 전환해야 할 때

```
/migration SharedPreferences를 DataStore로 전환해줘
→ brainstorming(위험 파일 분석) → migration-plan.md 생성
→ /phase 1
→ ...
```

---

## CLAUDE.md 연동 권장

이 플러그인은 프로젝트 루트의 `CLAUDE.md`에 팀 컨벤션이 정의되어 있을 때 더 정확하게 동작합니다.  
아래 항목을 `CLAUDE.md`에 추가하는 것을 권장합니다.

```markdown
## 팀 컨벤션
- 아키텍처: Clean Architecture + MVI
- 모듈 구조: :app / :feature / :domain / :data / :core
- 테스트: JUnit + Mockk (Android), XCTest (iOS)
- 코드 스타일: [팀 컨벤션 링크]
```
