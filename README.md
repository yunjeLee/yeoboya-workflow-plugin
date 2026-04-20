# yeoboya-workflow-plugin

앱팀 공통 개발 워크플로우 플러그인 (Android / iOS)

Claude Code 를 처음 쓰는 팀원도 명령어 한 줄로 기획 → 설계 → 구현 → 검증까지 표준 흐름을 따를 수 있습니다.

---

## 전체 플로우

### (최초 1 회 또는 신규 팀원 합류 시)

```
/onboard
  ├─ 처음: CLAUDE.md + docs/ 세트 자동 생성 (핵심 문서 4 종 + UI_GUIDE + WORKFLOW)
  ├─ 일부만 있음: 없는 파일만 보완
  └─ 전부 있음: 신규 팀원 브리핑 (프로젝트 구조 + 워크플로우 요약)

이후 모든 스킬은 CLAUDE.md 의 @ 참조로 docs/ 를 자동 로드
docs/ 없이 /feature·/bugfix 실행 시 /onboard 권유
```

### feature

```
/feature [기획서.pdf 또는 텍스트 설명]

         ↓

[선택] 브랜치 격리
  using-git-worktrees

         ↓

플랫폼 자동 감지 (Android / iOS)
요구사항 / 코드베이스 분석 (brainstorming)
구현 계획 작성 → feature-plan.md 저장

         ↓  context clear 후

/phase   ← plan.md 보고 단계별 실행

         ↓

각 Task 마다
  └─ [subagent] writer  ← TDD 또는 executing-plans 선택 후 구현
  └─ 테스트 1 회 실행   ← 실패 시 사용자에게 처리 방향 질문

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
| `/onboard` | Claude Code 를 프로젝트에 처음 연결 — 하네스 문서 세트 생성 또는 신규 팀원 브리핑 | [SKILL.md](skills/onboard/SKILL.md) |
| `/feature` | 기획서(PDF) 또는 설명으로 기능 개발 | [SKILL.md](skills/feature/SKILL.md) |
| `/bugfix` | 버그 설명, 에러 로그, 스크린샷으로 버그 수정 | [SKILL.md](skills/bugfix/SKILL.md) |
| `/phase` | 작성된 plan.md 를 Phase 단위로 실행 | [SKILL.md](skills/phase/SKILL.md) |

---

## 설치

```bash
git clone https://github.com/yeoboya/yeoboya-workflow-plugin
```

> **주의:** 이 플러그인은 `superpowers` 플러그인에 의존합니다.
> Claude Code 플러그인 매니저가 자동으로 설치하지 않는 경우 별도로 설치하세요.

---

## 자주 쓰는 시나리오

### 처음 레포를 열었을 때 (또는 신규 팀원 합류)

```
/onboard
→ 플랫폼 감지 → 레포 스캔 → CLAUDE.md + docs/ 자동 생성
→ 이후 다른 스킬들이 자동으로 하네스 가드레일 사용
```

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

---

## CLAUDE.md 연동 권장

이 플러그인은 프로젝트 루트의 `CLAUDE.md` 에 팀 컨벤션이 정의되어 있을 때 더 정확하게 동작합니다.
아래 항목을 `CLAUDE.md` 에 추가하는 것을 권장합니다.

```markdown
## 팀 컨벤션
- 아키텍처: Clean Architecture + MVI
- 모듈 구조: :app / :feature / :domain / :data / :core
- 테스트: JUnit + Mockk (Android), XCTest (iOS)
- 코드 스타일: [팀 컨벤션 링크]
```
