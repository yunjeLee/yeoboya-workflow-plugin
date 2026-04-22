# yeoboya-workflow-plugin

**팀원이 Claude Code 를 어떻게 쓰든 한 방향으로 수렴시키는 하네스 플러그인**

Android / iOS 앱팀 공통. 누군가는 TDD 로, 누군가는 plan 없이, 누군가는
`/fix` 만 치더라도 — 같은 문서를 읽고, 같은 단계를 밟고, 같은 품질 기준에
도달하게 만듭니다.

---

## 왜 필요한가

Claude Code 를 팀 단위로 쓸 때 마주치는 3 가지 문제:

1. **Context rot** — 긴 대화에서 초반 맥락이 밀려나면서 답변 품질이 떨어진다.
2. **팀원별 사용 편차** — 어떤 팀원은 spec 을 쓰고 어떤 팀원은 바로 구현에
   들어간다. 같은 repo 에 서로 다른 스타일의 결과물이 쌓인다.
3. **문서화되지 않은 팀 규칙** — 아키텍처 / 컨벤션 / 피해야 할 것들이 사람 머릿속에만
   있고, Claude 는 매번 새로 추론한다.

이 플러그인은 이 3 가지를 **하네스 (guardrail) 기법** 으로 해결합니다.

---

## 어떻게 수렴시키는가 — 3 가지 핵심

### 1. `/onboard` — Spec Driven Development 로 하네스 문서 자동 생성

프로젝트 루트에서 `/onboard` 를 1 회 실행하면 Claude 가 대화형으로 다음 7 개
파일을 생성합니다.

| 파일 | 역할 |
|------|------|
| `CLAUDE.md` | 팀 규칙의 진입점. docs/ 를 `@` 참조 |
| `docs/PRD.md` | 이 앱이 뭘 하는지, 누구를 위한 건지 |
| `docs/ARCHITECTURE.md` | 모듈 구조, 데이터 흐름, 상태 관리 (자동 스캔) |
| `docs/ADR.md` | 라이브러리 선택 이유와 트레이드오프 |
| `docs/TESTING.md` | 테스트 레벨, 네이밍, 커버리지, CI |
| `docs/CONVENTIONS.md` | 코드 스타일, 에러 처리, 커밋, push 정책 |
| `docs/UI_GUIDE.md` | 디자인 원칙 (디자인 시스템 감지 시) |

Claude 가 **레포를 먼저 스캔해서 예시를 만든 뒤** 팀원에게 1 개씩 순차 질문을
던집니다. 팀원은 선택지 번호만 누르거나 직접 입력하면 spec 이 완성됩니다.

### 2. `shared/context-manager.md` — context rot 방지 규칙

모든 skill 은 이 문서의 규칙을 따릅니다:

- **1 세션 = 1 목적** — 하나의 Phase 또는 Task 만 수행
- **상태는 plan.md 에 산다** — `{skill}-plan.md` 체크리스트가 유일한 진척 기록
- **/clear 유도 타이밍 3 가지**
  - ① Phase 전환 직후 (필수)
  - ② 컨텍스트 50% 초과 (권장)
  - ③ 작업 이탈 감지 (필수) — `/feature` 중 "버그", "크래시" 등 키워드 나오면 `/bugfix` 전환 제안

덕분에 긴 대화에서 맥락이 무너지기 전에 잘라낼 수 있습니다.

### 3. Skill 체계 — 모든 skill 이 `@docs/` 를 읽고 같은 방향으로 간다

각 skill 은 실행 초기에 `docs/` 6 종의 존재 여부를 확인하고, 없으면 `/onboard`
를 권유합니다. 이로써 팀원이 어떤 skill 을 치든 **같은 하네스 위에서** 동작합니다.

---

## 설치

### 1. superpowers 선 설치

이 플러그인은 `superpowers` 의 스킬(`brainstorming`, `writing-plans`,
`systematic-debugging`, `test-driven-development` 등)을 호출합니다.

```
/plugin marketplace add obra/superpowers
/plugin install superpowers@superpowers
```

### 2. yeoboya-workflow 설치

```
/plugin marketplace add yunjeLee/yeoboya-workflow-plugin
/plugin install yeoboya-workflow@yeoboya-apps
```

### 3. 업데이트

```
/plugin marketplace update yeoboya-apps
```

---

## 시작하기

```
/onboard
```

처음 쓰는 레포에서 `/onboard` 를 1 회 실행하면 나머지는 자동입니다.

- **핵심 문서 0 개**: 전체 생성 모드 (대화형)
- **일부 있음**: 없는 것만 보완
- **6 개 전부 있음**: 신규 팀원 브리핑 모드

---

## 명령어 레퍼런스

| 명령어 | 언제 | 상세 |
|--------|------|------|
| `/onboard` | 레포 최초 연결 / 신규 팀원 합류 | [SKILL.md](skills/onboard/SKILL.md) |
| `/feature` | 기획서(PDF) 또는 설명으로 기능 개발 | [SKILL.md](skills/feature/SKILL.md) |
| `/bugfix` | 버그 설명 / 에러 로그 / 스크린샷 | [SKILL.md](skills/bugfix/SKILL.md) |
| `/phase` | 작성된 plan.md 를 Phase 단위로 실행 | [SKILL.md](skills/phase/SKILL.md) |
| `/verify-docs` | docs/ 수정 후 모호성 · 규칙 충돌 · 참조 깨짐 재검증 | [SKILL.md](skills/verify-docs/SKILL.md) |

### feature 흐름

```
/feature [기획서.pdf 또는 텍스트 설명]
         ↓
[선택] 브랜치 격리 (using-git-worktrees)
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
```

### bugfix 흐름

```
/bugfix [버그 설명 / 에러 로그 / 스크린샷]
         ↓
[선택] 브랜치 격리
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

## 더 깊이 — 팀 가이드

개념 / 다이어그램 / 각 문서 작성 가이드 / 실전 시나리오 →
**[TEAM_GUIDE.html](TEAM_GUIDE.html)** (브라우저로 열기)

---

## 향후 개선 (TODO)

- **Hooks 기반 강제 장치**: `context-manager.md` 의 ②(50%) / ③(이탈) 권장 규칙을
  Claude Code 의 `SessionStart` / `Stop` / `PreToolUse` hook 으로 자동화한다.
