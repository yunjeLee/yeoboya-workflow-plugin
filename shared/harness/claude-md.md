# claude-md 모듈

호출자 (`/harness`, `/harness-edit`) 가 Read tool 로 읽고 지침을 따른다. 다른 7 개 모듈과 다르게 `@docs/...` 참조 블록을 메인으로 한다. 3 개 대화형 질문 (예시 생성 + 기본 템플릿 확인 2 회).

## 대상 파일

`CLAUDE.md` (프로젝트 루트)

## 사전 스캔

### 입력 소스 (우선순위 순)

1. 레포 내 설정 파일:
   - Android: `build.gradle(.kts)`, `libs.versions.toml`, `settings.gradle(.kts)`, `detekt.yml`, `.editorconfig`, `ktlint` 설정
   - iOS: `Package.swift`, `Info.plist`, `*.xcodeproj`, `.swiftlint.yml`, `.swiftformat`, `.editorconfig`
2. `~/.claude/CLAUDE.md` (user-level) — **선택적 참조**:
   - 파일 존재 시 사용자에게 "팀 공통 컨벤션(`~/.claude/CLAUDE.md`) 이 있습니다. 참고할까요? [y/N]" 질문.
   - `y` 일 때만 해당 파일의 "팀 컨벤션", "사용 라이브러리", "피해야 할 것" 섹션을 참고 소스로 사용.
3. 대화형 질문 — 위 두 소스로 못 채운 항목만.

### 결과 형식

- 프로젝트명 (`settings.gradle.kts` 의 `rootProject.name` 또는 `Info.plist` 의 `CFBundleName`)
- 기술 스택 (사용 라이브러리에서 자동 추출)
- 최소 SDK (Android `minSdk`, iOS `IPHONEOS_DEPLOYMENT_TARGET`)
- 모듈 구조 / 라이브러리 사용 패턴 (CRITICAL 예시 생성 용)
- `~/.claude/CLAUDE.md` 참고 동의 여부

## 섹션 목록

| 섹션 ID | 헤더 | 타입 | 질문 수 |
|--------|-----|-----|--------|
| s1 | `## CRITICAL 규칙` | 대화형 (예시 생성형) | 1 |
| s2 | `## 피해야 할 것 (AVOID)` | 대화형 (기본 템플릿 확인) | 1 |
| s3 | `## Claude Code 응답 규칙` | 대화형 (기본 템플릿 확인) | 1 |
| s4 | `## (참조 블록 + 외부 문서 가이드)` | 정적 | 0 |

> s4 는 `## 아키텍처` (`@docs/ARCHITECTURE.md`), `## 팀 컨벤션 / 작업 규칙` (`@docs/CONVENTIONS.md`), `## 외부 문서 (필요 시 Read)` 3 개 H2 묶음이다. 앞 2 개만 `@` 참조로 매 turn 자동 적재되고, 나머지 4 개 docs (PRD / ADR / UI_GUIDE / TESTING) 는 "외부 문서 (필요 시 Read)" 가이드에 한 줄씩 명시되어 LLM 이 필요할 때 Read 한다. 부분 수정 시 3 개 H2 묶음 단위로 다룬다.

## 섹션별 생성 로직

### s1: CRITICAL 규칙 (예시 생성형)

레포의 모듈 구조 및 주요 라이브러리 사용 패턴을 스캔해 **예시 2~3 개** 를 만든 뒤 아래 형식으로 출력한다.

#### 공통 출력 형식

```
[CRITICAL 규칙]
이 프로젝트에 구조적으로 절대 위반하면 안 되는 규칙이 있다면 선택하거나 직접 입력해주세요.

레포 스캔 결과 (추정):
  {모듈 목록 / 주요 라이브러리 요약}

아래 중 가깝거나 직접 입력해주세요:
  1) {예시 1} (매칭: {근거})
  2) {예시 2} (매칭: {근거})
  3) {예시 3} (매칭: {근거})
  4) 직접 입력 (1~2 개까지)
  5) 없음

번호 선택 또는 직접 입력:
```

#### 예시 생성 소스 (감지 패턴 → 예시)

| 감지 패턴 | 예시 |
|----------|------|
| `:data` 모듈 존재 | "모든 API / 외부 DB 호출은 `:data` 모듈에서만" |
| `:domain` 모듈 + UseCase 파일 | "비즈니스 로직은 UseCase 계층에서만. ViewModel 은 UseCase 만 호출" |
| Hilt 사용 | "Direct singleton 접근 금지. 모든 의존성은 constructor injection 으로" |
| Compose + ViewModel | "Composable 내 ViewModel 직접 생성 금지. `hiltViewModel()` 또는 파라미터 주입" |
| Coroutine 사용 | "GlobalScope 사용 금지. ViewModelScope / LifecycleScope 사용" |

스캔 매칭 실패 시: 일반 템플릿 예시 제시, 매칭 근거 위치에 `(일반 템플릿)` 표기.

#### 처리 규칙

- `1`/`2`/`3` 선택 → 해당 예시 그대로 채택.
- `4` → 자유 입력 (1~2 개까지).
- `5` 또는 `없음` → 플레이스홀더 `- (TBD — 나중에 채워주세요)` 로 표기.

### s2: 피해야 할 것 (기본 템플릿 확인)

아래 기본 템플릿을 보여주고 "이대로 쓸까요? 수정할 부분이 있나요? [기본/수정]" 질문.

#### 기본 템플릿 (Android)

```
- 의미 없는 추상화
- 과도한 generic / base class 설계
- direct singleton 남용
- lifecycle 을 무시한 상태 처리
- Compose 에서 상태 소유권이 불명확한 구조
- Context 의존성이 퍼지는 구조
- "일단 동작만 하는" 임시 코드
- 현재 프로젝트 문맥을 무시한 과한 리팩토링
```

#### 기본 템플릿 (iOS)

```
- 의미 없는 추상화
- 과도한 protocol / generic 설계
- singleton 남용
- ARC / retain cycle 을 무시한 클로저 캡처
- Combine / SwiftUI 에서 상태 소유권이 불명확한 구조
- AppDelegate 의존성이 퍼지는 구조
- "일단 동작만 하는" 임시 코드
- 현재 프로젝트 문맥을 무시한 과한 리팩토링
```

`~/.claude/CLAUDE.md` 에 "피해야 할 것" 섹션이 있고 참고 동의한 경우, 그 내용을 기본 템플릿 대신 제시.

### s3: Claude Code 응답 규칙 (기본 템플릿 확인)

아래 기본 템플릿을 보여주고 "이대로 쓸까요? 수정할 부분이 있나요? [기본/수정]" 질문.

```
- 응답 언어: 한국어
- 응답 순서: 문제 요약 → 원인/구조 → 해결 방향 → 추천안 → 코드 예시
- 코드 예시: Kotlin (Android) / Swift (iOS), 복붙 가능한 Markdown
- 불확실한 내용: 추측하지 말고 "추정" 이라고 명시
- "정답" 단정 금지, trade-off 함께 제시
- 코드 수정 전 변경안 먼저 제시하고 확인 후 진행
- 장황한 이론보다 실무 적용 중심 설명
```

### s4: 참조 블록 + 외부 문서 가이드 (정적)

매 turn 자동 적재 (`@` 참조) 대상은 **2 개로 제한**한다 — `@docs/ARCHITECTURE.md`, `@docs/CONVENTIONS.md`. 나머지 4 개 (PRD / ADR / UI_GUIDE / TESTING) 는 `## 외부 문서 (필요 시 Read)` 섹션의 가이드 리스트로 기록하여 LLM 이 필요할 때 Read tool 로 읽도록 한다. 대화 없음.

가이드 리스트는 출력 템플릿의 형식 그대로 생성한다. UI_GUIDE.md 가 생성되지 않은 프로젝트 (Case 2 에서 UI_GUIDE 부재) 라면 UI_GUIDE 줄만 제외하고 나머지 3 줄은 그대로 기록한다.

> 결정 근거: `/harness-validate` 측정 결과 (`docs/superpowers/progress/2026-05-12-harness-compactness.md`) — 6 개 모두 자동 적재 시 prefix ≈ 8K 토큰이 매 LLM call 마다 cache_read 로 누적. 핵심 2 개만 적재 + 나머지는 on-demand Read 로 prefix ~50% 감소 효과 확보.

## 출력 템플릿

````markdown
# 프로젝트: {프로젝트명}

## 아키텍처
@docs/ARCHITECTURE.md

## 팀 컨벤션 / 작업 규칙
@docs/CONVENTIONS.md

## CRITICAL 규칙
{s1 에서 수집된 CRITICAL 규칙 리스트}

## 피해야 할 것 (AVOID)
{s2 에서 최종 확정된 리스트}

## Claude Code 응답 규칙
{s3 에서 최종 확정된 리스트}

## 외부 문서 (필요 시 Read)
- docs/PRD.md       — 새 화면 / 기능 설계 시
- docs/ADR.md       — DI / 모듈 / 라이브러리 선택 논의 시
- docs/UI_GUIDE.md  — Compose 화면 작성 시 (디자인 시스템 컴포넌트 확인 필수)
- docs/TESTING.md   — 테스트 코드 작성 시
````

> 팀 컨벤션 / 작업 규칙 / 사용 라이브러리 등은 `docs/CONVENTIONS.md` 에서 수집한다. CLAUDE.md 는 `@` 참조로 위임. `~/.claude/CLAUDE.md` 참고에 동의한 경우 해당 파일의 "피해야 할 것", "팀 컨벤션", "리팩토링 원칙", "우선순위" 등을 conventions 모듈의 예시 생성에 활용한다.
