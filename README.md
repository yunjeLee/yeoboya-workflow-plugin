# yeoboya-workflow-plugin

**팀원이 Claude Code 를 어떻게 쓰든 한 방향으로 수렴시키는 하네스 플러그인**

Android / iOS 앱팀 공통.

---

## 1. harness 가 필요한 이유

팀 단위로 Claude Code 를 쓰면 마주치는 3 가지 문제가 있다.

1. **사용 편차** — 어떤 팀원은 spec 부터 쓰고, 어떤 팀원은 바로 구현에 들어간다.
   같은 repo 에 서로 다른 스타일의 결과물이 쌓인다.
2. **문서화되지 않은 팀 규칙** — 아키텍처 / 컨벤션 / 피해야 할 것이 사람 머릿속에만
   있고 Claude 는 매번 새로 추론한다.
3. **context rot** — 긴 대화에서 초반 맥락이 밀려나면서 답변 품질이 떨어진다.

이 plugin 은 두 가지 전략으로 위 문제를 해결한다.

- **하네스 문서 7 종** — `CLAUDE.md` + `docs/` 6 개 문서. 팀이 한 번 작성해두면
  Claude 가 세션 시작 시 자동으로 읽는다. spec-driven-development 의 사양 역할.
- **context-manager 규칙** — Phase 전환 / context 50% 초과 / 작업 이탈 3 가지
  시점에 `/clear` 를 유도해 context rot 을 끊는다.

결과적으로 누가 쓰든, 어떻게 쓰든 같은 방향으로 수렴한다.

---

## 2. 설치 방법

### superpowers 선 설치

이 plugin 은 `superpowers` 의 스킬 (`brainstorming`, `writing-plans`,
`systematic-debugging`, `test-driven-development` 등) 을 호출한다.

```
/plugin marketplace add obra/superpowers
/plugin install superpowers@superpowers
```

### yeoboya-workflow 설치

```
/plugin marketplace add yunjeLee/yeoboya-workflow-plugin
/plugin install yeoboya-workflow@yeoboya-apps
```

### 업데이트

```
/plugin marketplace update yeoboya-apps
```

---

## 3. 스킬 및 규칙 설명

### `/harness` — 하네스 문서 생성 / 보완

팀원이 Claude Code 를 어떻게 쓰든 같은 방향으로 수렴시키는 가드레일 문서를 생성한다.
`CLAUDE.md` + 6 개 하네스 문서, 총 7 개 문서로 구성되며 세션 시작 시 / Skill 시작 시
자동으로 읽혀 작업의 기준이 된다.

| 문서 | 역할 |
|------|------|
| `CLAUDE.md` | 6 개 docs 를 `@` 로 참조하는 진입점 + CRITICAL 규칙 / 피해야 할 것 / Claude 응답 규칙 |
| `docs/PRD.md` | 앱이 뭘 하는지 / 누구를 위한 건지 / 핵심 가치 / 출시 단계 / 지원하지 않는 것 |
| `docs/ARCHITECTURE.md` | 모듈 구조 / 데이터 흐름 / 아키텍처 패턴 / 상태 관리. 빌드 파일 자동 스캔으로 100% 자동 생성 |
| `docs/CONVENTIONS.md` | 코드 스타일 / 에러 처리 / 로깅 / Claude 작업 스코프 / 커밋 / push 정책 |
| `docs/ADR.md` | 라이브러리 선택 결정 + 트레이드오프 (네트워크 · DI · 이미지 · 로컬저장 · 네비게이션 · UI) |
| `docs/TESTING.md` | 테스트 레벨 / 네이밍 / 커버리지 목표 / CI / 라이브러리 |
| `docs/UI_GUIDE.md` | 디자인 원칙 / 색상 토큰 / 컴포넌트 커스터마이징 / 디자인 금지 항목 (Figma 가 토큰화 안 된 프로젝트만) |

**작동 방식**

1. Claude 가 git 기록 + 모듈 구조 + 설정 파일을 읽어 프로젝트 개념 / 아키텍처를 사전 파악.
2. 사전 정의된 카테고리별 질문을 1 개씩 순차 제시. 3~5 개 선택지 + 직접 입력 형태로 답변 유도.
3. 위 과정으로 7 개 문서가 완성된다.

**작성 / 관리 정책**

- 7 개 문서는 **각 서비스별로 모든 팀원이 참여해 작성** 한다.
- harness 문서는 remote 에 push 하는 문서이며, **전체 마이그레이션이나 팀 규칙이 바뀌어야**
  변경할 수 있다. 예외 수정은 팀원과 상의 후 진행.

---

### `/harness-module` — 모듈 단위 CLAUDE.md 생성

루트 하네스가 이미 있는 프로젝트에서 **모듈 단위 `CLAUDE.md`** 와
**`docs/MODULE_MAP.md` 인덱스** 를 생성한다.

각 모듈의 책임 / 진입 파일 / 비자명적 패턴(함정) / 의존 관계를 25~50 줄로 정리해
AI 가 모듈에 진입하는 즉시 무엇을 해야 하는지 알 수 있게 한다.

**점수 기반 휴리스틱** (수정 빈도 + 팬인 + 레거시/신규 혼재) 으로 후보 모듈을 자동
추천. 사용자는 `[Y/n]` 으로 확인하거나 일괄 예외만 입력한다.

---

### `/harness-edit {파일명}` — 특정 하네스 파일 대화형 수정

이미 작성된 하네스 문서의 특정 섹션을 대화형으로 수정한다.

파일명: `claude-md`, `prd`, `adr`, `architecture`, `testing`, `conventions`,
`ui-guide` 중 하나. 인자 없이 호출하면 목록에서 선택할 수 있다.

---

### `/harness-critique` — 문서 품질 검증

작성된 하네스 문서 세트를 5 축으로 검증한다.

- **모호성** — 해석 여지가 있는 표현
- **일관성** — 문서 간 충돌
- **완전성** — 빠진 정보
- **참조 무결성** — `@docs/` 깨진 링크
- **레포 실상** — 문서와 실제 코드의 괴리

작성 직후 1 회 / 큰 변경 후 정기적으로 실행한다.

---

### `context-manager` — context rot 방지 공통 규칙

`shared/context-manager.md` 는 슬래시 명령이 아니라 **모든 skill 이 따르는 공통 규칙** 이다.

- **1 세션 = 1 목적** — 하나의 Phase 또는 Task 만 수행
- **상태는 plan.md 에 산다** — `{skill}-plan.md` 체크리스트가 유일한 진척 기록
- **`/clear` 유도 3 시점** (Hooks 로 자동화):
  - ① Phase 전환 직후 (필수)
  - ② context 50% 초과 (권장)
  - ③ 작업 이탈 감지 (필수) — `/feature` 중 "버그", "크래시" 키워드 등장 시
    `/bugfix` 전환 제안
