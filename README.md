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

### 1. `/harness` — Spec Driven Development 로 하네스 문서 생성/보완

프로젝트 루트에서 `/harness` 를 1 회 실행하면 Claude 가 대화형으로 다음 7 개
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

부분 수정은 `/harness-edit {모듈명}`, 검증은 `/harness-critique`, 신규 팀원
브리핑은 `/onboard` 로 책임이 분리되어 있습니다.

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

각 skill 은 실행 초기에 `docs/` 6 종의 존재 여부를 확인하고, 없으면 `/harness`
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
/harness
```

처음 쓰는 레포에서 `/harness` 를 1 회 실행하면 8 개 모듈이 자동으로 7 개 하네스
파일을 만들거나 누락된 것만 보완합니다.

| 상태 | 동작 |
|------|------|
| 핵심 6 종 모두 부재 (Case 1) | 전체 생성 모드 |
| 핵심 6 종 일부 부재 (Case 2) | 누락된 것만 보완 |
| 8 종 모두 존재 | 종료 안내 — 수정/검증/브리핑 명령으로 가이드 |

---

## 명령어 레퍼런스

| 명령어 | 언제 | 상세 |
|--------|------|------|
| `/harness` | 레포 최초 연결 / 누락된 하네스 보완 | [SKILL.md](skills/harness/SKILL.md) |
| `/harness-edit {모듈명}` | 특정 하네스 문서의 섹션 단위 수정 | [SKILL.md](skills/harness-edit/SKILL.md) |
| `/harness-critique` | 5 축 (모호성/일관성/완전성/참조/실상) 품질 검증 | [SKILL.md](skills/harness-critique/SKILL.md) |
| `/onboard` | 신규 팀원 브리핑 (이미 하네스 세팅된 프로젝트) | [SKILL.md](skills/onboard/SKILL.md) |
| `/harness-module` | 모듈 단위 CLAUDE.md + 인덱스 생성 | [SKILL.md](skills/harness-module/SKILL.md) |
| `/feature` | 기획서(PDF) 또는 설명으로 기능 개발 | [SKILL.md](skills/feature/SKILL.md) |
| `/bugfix` | 버그 설명 / 에러 로그 / 스크린샷 | [SKILL.md](skills/bugfix/SKILL.md) |
| `/phase` | 작성된 plan.md 를 Phase 단위로 실행 | [SKILL.md](skills/phase/SKILL.md) |

`/harness-edit` 의 모듈명: `claude-md`, `prd`, `adr`, `architecture`, `testing`,
`conventions`, `ui-guide`, `workflow` 중 하나. 인자 없이 호출하면 목록에서
선택할 수 있습니다.

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

## .md 직접 commit 차단 (v2.3.0+)

하네스 8 개 파일은 PreToolUse Hook 으로 **Claude 자동 commit/push 가 차단**됩니다.

대상:
- `CLAUDE.md`
- `docs/PRD.md`, `docs/ADR.md`, `docs/ARCHITECTURE.md`,
  `docs/TESTING.md`, `docs/CONVENTIONS.md`, `docs/UI_GUIDE.md`, `docs/WORKFLOW.md`

`/harness`, `/harness-edit` 가 만든 변경은 **사용자가 IDE 에서 직접 검토 후
commit/push** 하셔야 합니다. Claude 가 자기 판단으로 하네스 문서를 커밋하는
것을 막아 팀 규칙의 변경 추적성을 보장합니다.

---

## 마이그레이션 (v2.2.x → v2.3.0)

`/onboard` 한 명령어가 책임별로 4 개 명령어로 분리되었습니다.

| v2.2.x | v2.3.0 |
|--------|--------|
| `/onboard` (전체 생성) | `/harness` |
| `/onboard` (누락 보완) | `/harness` (Case 2 자동 분기) |
| `/onboard` (브리핑) | `/onboard` (브리핑 전용) |
| `/verify-docs` | `/harness-critique` (이름 변경) |
| (없음) | `/harness-edit {모듈명}` (섹션 단위 수정 — 신규) |

**동작 변경:**
- 기존 `/onboard` 의 자동 분기(부재 시 생성 / 존재 시 브리핑) 동작은 사라졌습니다.
- 신규 프로젝트는 반드시 `/harness` 부터 시작.
- `/onboard` 는 하네스가 모두 존재할 때만 동작 (브리핑 전용).
- `/verify-docs` alias 는 유지하지 않음 — `/harness-critique` 만 동작.

---

## 더 깊이 — 팀 가이드

개념 / 다이어그램 / 각 문서 작성 가이드 / 실전 시나리오 →
**[TEAM_GUIDE.html](TEAM_GUIDE.html)** (브라우저로 열기)

---

## 향후 개선 (TODO)

- **context-manager Hooks 자동화**: `context-manager.md` 의 ②(50%) / ③(이탈)
  권장 규칙을 Claude Code 의 `SessionStart` / `Stop` 처럼 추가 hook 으로 자동화.
  (v2.3.0 에서 PreToolUse 2 개 — plugin 내부 보호 / 하네스 commit 차단 — 이
  먼저 추가됨.)
- **`/harness-module` 후속 spec**:
  - 자동 freshness (PR/커밋 기반 모듈 CLAUDE.md 갱신)
  - PR/커밋 마이닝으로 Q3/Q5 (안티 패턴 / 명시되지 않은 규칙) 자동 추출
  - `/harness-edit` / `/harness-critique` 의 모듈 CLAUDE.md 지원
  - 평가 HTML 산출 (7 항목 채점 리포트)
