# Onboard — Case 1/2 생성 모드

`/onboard` 의 Case 1 (전체 생성) 또는 Case 2 (일부 보완) 진입 시 이 문서의 지침을 따른다.

## 규칙

1. **Case 2 에서는 기존 파일을 절대 수정하지 않는다.** 누락된 파일만 생성한다. 아래 6 개 섹션 중 해당 파일이 이미 존재하면 그 섹션은 건너뛴다.
2. 각 파일은 아래 섹션의 생성 전략을 따른다.
3. 생성 불가능하거나 입력이 부족한 항목은 `[TBD]` 플레이스홀더로 남긴다. 임의 값으로 채우지 않는다.
4. **섹션 번호(1~6)는 문서 설명 순서이며, 실제 파일 저장 순서는 아래 목록과 다르다.** 저장 순서를 반드시 따른다 — CLAUDE.md 가 docs/ 를 `@` 참조하므로 docs/ 전체를 먼저 저장하고 CLAUDE.md 를 마지막에 저장한다.

생성 순서 (실제 파일 저장 순):
1. `docs/PRD.md` (대화형)
2. `docs/ARCHITECTURE.md` (자동 스캔)
3. `docs/ADR.md` (반자동)
4. `docs/UI_GUIDE.md` (조건부)
5. `docs/WORKFLOW.md` (정적 템플릿)
6. `CLAUDE.md` (스캔 + 대화, docs/ 를 `@` 로 참조)

---

## 1. CLAUDE.md 생성

### 입력 소스 (우선순위 순)

1. 레포 내 설정 파일:
   - Android: `build.gradle(.kts)`, `libs.versions.toml`, `settings.gradle(.kts)`, `detekt.yml`, `.editorconfig`, `ktlint` 설정
   - iOS: `Package.swift`, `Info.plist`, `*.xcodeproj`, `.swiftlint.yml`, `.swiftformat`, `.editorconfig`
2. `~/.claude/CLAUDE.md` (user-level) — **선택적 참조**:
   - 파일 존재 시 사용자에게 "팀 공통 컨벤션(`~/.claude/CLAUDE.md`) 이 있습니다. 참고할까요? [y/N]" 질문
   - `y` 일 때만 해당 파일의 "팀 컨벤션", "사용 라이브러리", "피해야 할 것" 섹션을 참고 소스로 사용
3. 대화형 질문 — 위 두 소스로 못 채운 항목만

### 생성 절차

**1. 기본값 자동 수집**

- 프로젝트명: `settings.gradle.kts` 의 `rootProject.name` 또는 `Info.plist` 의 `CFBundleName`
- 기술 스택: 사용 라이브러리에서 자동 추출
- 최소 SDK: Android `minSdk`, iOS `IPHONEOS_DEPLOYMENT_TARGET`

**2. CRITICAL 규칙 수집 (예시 생성형)**

레포의 모듈 구조 및 주요 라이브러리 사용 패턴을 스캔해 **예시 2~3 개** 를 만든 뒤 아래 형식으로 출력한다.

**공통 출력 형식:**
```
[CRITICAL 규칙]
이 프로젝트에 구조적으로 절대 위반하면 안 되는 규칙이 있다면 선택하거나 직접 입력해주세요.

레포 스캔 결과 (가정):
  {모듈 목록 / 주요 라이브러리 요약}

아래 중 가깝거나 직접 입력해주세요:
  1) {예시 1} (매칭: {근거})
  2) {예시 2} (매칭: {근거})
  3) {예시 3} (매칭: {근거})
  4) 직접 입력 (1~2 개까지)
  5) 없음

번호 선택 또는 직접 입력:
```

**예시 생성 소스 (감지 패턴 → 예시)**:

| 감지 패턴 | 예시 |
|----------|------|
| `:data` 모듈 존재 | "모든 API / 외부 DB 호출은 `:data` 모듈에서만" |
| `:domain` 모듈 + UseCase 파일 | "비즈니스 로직은 UseCase 계층에서만. ViewModel 은 UseCase 만 호출" |
| Hilt 사용 | "Direct singleton 접근 금지. 모든 의존성은 constructor injection 으로" |
| Compose + ViewModel | "Composable 내 ViewModel 직접 생성 금지. `hiltViewModel()` 또는 파라미터 주입" |
| Coroutine 사용 | "GlobalScope 사용 금지. ViewModelScope / LifecycleScope 사용" |

스캔 매칭 실패 시: 일반 템플릿 예시 제시, 매칭 근거 위치에 `(일반 템플릿)` 표기.

**처리 규칙**:
- `1`/`2`/`3` 선택 → 해당 예시 그대로 채택
- `4` → 자유 입력 (1~2 개까지)
- `5` 또는 `없음` → 플레이스홀더 `- (TBD — 나중에 채워주세요)` 로 표기

**3. 피해야 할 것 제시 (기본 템플릿 확인)**

아래 기본 템플릿을 보여주고 "이대로 쓸까요? 수정할 부분이 있나요? [기본/수정]" 질문.

기본 템플릿 (Android):
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

기본 템플릿 (iOS):
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

**4. Claude Code 응답 규칙 제시 (기본 템플릿 확인)**

아래 기본 템플릿을 보여주고 "이대로 쓸까요? 수정할 부분이 있나요? [기본/수정]" 질문.

```
- 응답 언어: 한국어
- 응답 순서: 문제 요약 → 원인/구조 → 해결 방향 → 추천안 → 코드 예시
- 코드 예시: Kotlin (Android) / Swift (iOS), 복붙 가능한 Markdown
- 불확실한 내용: 추측하지 말고 "가정" 이라고 명시
- "정답" 단정 금지, trade-off 함께 제시
- 코드 수정 전 변경안 먼저 제시하고 확인 후 진행
- 장황한 이론보다 실무 적용 중심 설명
```

**5. 팀 컨벤션 수집**

- `~/.claude/CLAUDE.md` 참고 동의한 경우: 해당 파일의 "팀 컨벤션", "사용 라이브러리" 섹션에서 발췌
- 아니면: 레포 설정 파일에서 추출 가능한 값(linter 규칙, 커밋 컨벤션 등) + 대화로 누락 항목 수집

**6. 파일 작성 — 아래 템플릿 사용**

```markdown
# 프로젝트: {프로젝트명}

## 프로덕트 개요
@docs/PRD.md

## 아키텍처
@docs/ARCHITECTURE.md

## 기술 결정 (ADR)
@docs/ADR.md

## 디자인 가이드
@docs/UI_GUIDE.md

## CRITICAL 규칙
{2번에서 수집된 CRITICAL 규칙 리스트}

## 피해야 할 것 (AVOID)
{3번에서 최종 확정된 리스트}

## Claude Code 응답 규칙
{4번에서 최종 확정된 리스트}

## 팀 컨벤션
{5번에서 수집된 리스트}
```

---

## 2. docs/ARCHITECTURE.md 생성 (자동 스캔 100%)

### Android 스캔 절차

1. `settings.gradle(.kts)` Read → `include(":xxx")` 패턴으로 모듈 목록 추출
2. 각 모듈의 소스 디렉토리 Glob 으로 패키지 트리(2 레벨) 추출:
   - 먼저 모듈 이름(`:feature:home`)의 `:` 를 `/` 로 치환해 경로 생성 (`feature/home`)
   - Glob 우선순위: `{모듈 경로}/src/main/java/**/*.kt` → `{모듈 경로}/src/main/kotlin/**/*.kt`
   - 둘 다 비어있으면 `{모듈 경로}/**/*.kt` 로 fallback
3. 각 모듈의 `build.gradle(.kts)` Read → `dependencies { ... implementation(project(":xxx")) }` 패턴으로 모듈 간 관계 확인
4. 사용 라이브러리로부터 패턴 추정:
   - `hilt-android` 또는 `dagger.hilt.*` → DI = Hilt
   - `androidx.compose.*` → UI 시스템 = Jetpack Compose
   - `kotlinx.coroutines.*` + `flow` → 상태 관리 = Flow / StateFlow
   - `androidx.lifecycle.*` → lifecycle-aware
5. Clean Architecture / MVI 여부: 모듈 이름에 `:domain`, `:data`, `:feature` 가 있으면 Clean. `reduce`, `Intent`, `SideEffect` 같은 키워드가 있으면 MVI. 확실하지 않으면 대화로 확인.

### iOS 스캔 절차

1. `Package.swift` Read → `targets: [ .target(name: "xxx") ]` 에서 타겟 목록 추출
2. `*.xcodeproj/project.pbxproj` Read → `PBXGroup` 섹션에서 폴더 구조 추출
3. `Podfile` 또는 `Cartfile` Read → 외부 의존성 목록
4. 파일 구조로부터 패턴 추정 (`Sources/Features/`, `Sources/Domain/`, `Sources/Data/` 존재 → Clean Architecture)

### 출력 템플릿

```markdown
# 아키텍처

## 디렉토리 구조
{실제 스캔 결과 트리 — 각 모듈/타겟 오른쪽에 1 줄 역할 표시. 도출 불가 시 [TBD]}

## 패턴
- 아키텍처: {Clean Architecture / MVC / MVVM / 직접 입력 / [TBD]}
- 디자인 패턴: {MVI / MVVM / Redux / [TBD]}
- UI 시스템: {Jetpack Compose / XML / SwiftUI / UIKit / [TBD]}

## 데이터 흐름
{UI → ViewModel → UseCase → Repository → DataSource 형태의 다이어그램.
 모듈 구조에서 역추출 불가하면 [TBD]}

## 상태 관리
{StateFlow / LiveData / Combine Publisher / [TBD]}
```

---

## 3. docs/ADR.md 생성 (반자동)

### 자동 추출 — 카테고리화

`libs.versions.toml` (Android) 또는 `Podfile` (iOS) 의 라이브러리를 아래 카테고리로 분류:

| 카테고리 | Android 예시 | iOS 예시 |
|---------|-------------|---------|
| 네트워크 | Retrofit, OkHttp, Ktor | Alamofire, URLSession |
| DI | Hilt, Dagger, Koin | Swinject, Needle |
| 이미지 | Coil, Glide, Fresco | Kingfisher, SDWebImage |
| 로컬 저장 | DataStore, Room, SQLDelight | CoreData, Realm, GRDB |
| 네비게이션 | Navigation Compose, Jetpack Navigation | SwiftUINavigation, Coordinator |
| UI | Compose, XML | SwiftUI, UIKit |

각 카테고리에서 가장 우세한 라이브러리를 "결정된 라이브러리" 로 지정.

### 배치 질문 (한 번에)

```
아래 라이브러리 중 '이유와 트레이드오프' 를 꼭 남기고 싶은 것만 골라주세요:
1. 네트워크: {라이브러리명}
2. DI: {라이브러리명}
3. 이미지: {라이브러리명}
4. 로컬 저장: {라이브러리명}
5. 네비게이션: {라이브러리명}
6. UI: {라이브러리명}

번호를 쉼표로 입력 (예: 1,2,4). "전부 건너뛰기" 도 가능.
```

### 선택 항목 개별 질문 (예시 생성형)

선택된 카테고리 각각에 대해 **라이브러리별 일반 trade-off** 를 2~3 개씩 생성해 아래 형식으로 출력한다.

**공통 출력 형식:**
```
[{카테고리}: {라이브러리명}]

선택 이유 후보 (일반 템플릿):
  1) {이유 예시 1}
  2) {이유 예시 2}
  3) {이유 예시 3}
  4) 직접 입력

번호 선택 또는 직접 입력:

트레이드오프 / 포기한 것 후보 (일반 템플릿):
  1) {트레이드오프 예시 1}
  2) {트레이드오프 예시 2}
  3) {트레이드오프 예시 3}
  4) 직접 입력

번호 선택 또는 직접 입력:
```

**라이브러리별 예시 (주요):**

| 라이브러리 | 이유 예시 | 트레이드오프 예시 |
|----------|---------|----------------|
| Retrofit | 코루틴 suspend 지원, OkHttp 인터셉터 활용, 표준적 | 초기 설정 번거로움, 대용량 스트리밍 불리 |
| Hilt | Dagger 기반 검증된 DI, Android 통합 편리 | 빌드 시간 증가, 학습 곡선 |
| Coil | Compose 통합 우수, Kotlin 네이티브 | Glide 대비 캐시 성능 낮을 수 있음 |
| DataStore | Preferences 후속, 코루틴 네이티브 | 대용량 구조화 데이터 부적합 |
| Navigation Compose | Compose 공식, type-safe 지원 | deep link 처리 제약, nested graph 복잡 |
| Kingfisher (iOS) | SwiftUI / UIKit 양쪽 지원, 안정적 | SDWebImage 대비 커뮤니티 규모 작음 |
| Alamofire | 표준적, 체이닝 API 편리 | URLSession 대비 추가 의존성 |

표에 없는 라이브러리 → `(일반 템플릿)` 으로 표기하고 통상적 이유 / 트레이드오프 추정.

**건너뛰기**: 각 질문에서 `skip` / `없음` / 빈 줄 → 해당 필드 `[TBD]`.

### 출력 템플릿

```markdown
# Architecture Decision Records

## 철학
{대화: "이 프로젝트의 핵심 가치관을 한 줄로 (예: 유지보수성 > 화려한 코드). 건너뛰기 가능." → 입력값 또는 [TBD]}

---

### ADR-001: {카테고리 1}: {라이브러리명}
**결정**: {라이브러리명}
**이유**: {입력값 또는 [TBD]}
**트레이드오프**: {입력값 또는 [TBD]}

### ADR-002: ...
...
```

미선택 카테고리도 ADR 항목으로 포함하되 이유/트레이드오프는 `[TBD]` 표기.

---

## 4. docs/PRD.md 생성 (대화형, 예시 생성형)

### 사전 스캔

질문 시작 전 아래 소스를 Read / Glob / Bash 로 확인한다. 결과는 질문별 예시 생성에 사용한다.

| 소스 | 용도 |
|------|------|
| `README.md` 상단 1~2 문장 | 앱 설명, 외부 문서 링크 |
| `settings.gradle.kts` / `Package.swift` | 모듈 / 타겟명 (앱 영역 추론) |
| 패키지 루트 디렉토리 이름 | 도메인 추론 (`booking`, `payment`, `chat` 등) |
| `git tag --list` + `git log --oneline \| wc -l` | 출시 단계 추정 |

### 5 개 질문 순차 진행

각 질문은 아래 공통 출력 형식을 따른다.

**공통 출력 형식:**
```
[질문 N] {질문 내용}

레포 스캔 결과 (가정):
  {해당 질문에 쓴 스캔 소스 요약}

아래 중 가깝거나 직접 입력해주세요:
  1) {예시 1} (매칭: {근거})
  2) {예시 2} (매칭: {근거})
  3) {예시 3} (매칭: {근거})
  4) 직접 입력

번호 선택 또는 직접 입력 (건너뛰기 시 Enter → [TBD]):
```

**예시 생성 소스 (질문별):**

| # | 질문 | 예시 생성 소스 |
|---|------|------------|
| 1 | 이 앱이 뭘 하는지 1~2 문장 | 패키지명, 모듈명, README 한 줄 |
| 2 | 주 사용자 및 사용 맥락 | README 키워드, 모듈명 (`feature:reservation` → "호텔 예약 고객" 등) |
| 3 | 핵심 가치 1~3 개 | 일반 템플릿 ("유지보수성 > 화려한 코드", "빠른 학습 곡선", "실사용자 피드백 우선") |
| 4 | 출시 단계 (MVP / Growth / Mature) | `git tag` + commit 수로 추정 (tag 없음 + 커밋 < 50 → MVP, tag 있음 + 활발 → Growth, tag 있음 + 활발 X → Mature) |
| 5 | 외부 상세 문서 링크 | README 내 http(s) 링크 탐색 |

**스캔 소스 부재 시** (레포가 비어있거나 README 없음): 일반 템플릿 예시 2~3 개 제시, 매칭 근거 위치에 `(일반 템플릿)` 표기.

**건너뛰기 처리**: 빈 줄 / `건너뛰기` / `없음` / `스킵` / `skip` / `-` → `[TBD]`

### 출력 템플릿

> **주의**: "안 하는 것" 항목은 현재 버전의 5 개 질문에서 수집하지 않는다. 팀원이 나중에 채우도록 `[TBD]` 로 남긴다. (CLAUDE.md 의 `@docs/PRD.md` 참조는 그대로 유지되므로 추후 자동 연결됨)

```markdown
# 프로덕트 개요

## 이 앱이 하는 일
{1 번 답변 또는 [TBD]}

## 주요 사용자 & 사용 맥락
{2 번 답변 또는 [TBD]}

## 핵심 가치
{3 번 답변 — 리스트 형태로 렌더링. 없으면 [TBD]}

## 출시 상태
- 플랫폼: {자동 감지 결과}
- 단계: {4 번 답변 또는 [TBD]}

## 안 하는 것 (out of scope)
- [TBD]

## 외부 상세 문서
{5 번 답변 또는 [TBD]}
```

### 전부 건너뛰기 시

파일 최상단에 주석 추가:
```
<!-- 이 파일은 아직 채워지지 않았습니다. /onboard 를 다시 실행하거나 직접 편집하세요. -->
```

---

## 5. docs/UI_GUIDE.md 생성 (조건부)

### 감지 로직

**Android**:
- Glob: `**/ui/theme/Color.kt`, `**/ui/theme/Theme.kt`

**iOS**:
- Glob: `**/Assets.xcassets/**/Contents.json` (색상/이미지 에셋 존재 여부), `**/Theme.swift`, `**/DesignSystem*.swift`
- 결과가 비어있으면 `iOS`, `Apple` 색상 확장 코드(`extension Color` / `extension UIColor`) 를 Grep 으로 탐색해 fallback

### 감지 실패 시

```
디자인 시스템 코드가 감지되지 않았습니다.
docs/UI_GUIDE.md 를 생성할까요? [y/N]
```

- `N` (기본): **파일 생성하지 않음**. CLAUDE.md 의 `@docs/UI_GUIDE.md` 참조는 그대로 유지한다. 이렇게 두면 팀원이 나중에 수동으로 `docs/UI_GUIDE.md` 를 추가할 때 자동으로 가드레일에 연결된다. (참조 파일이 없을 때 Claude Code 의 정확한 동작은 환경에 따라 다를 수 있으나, 팀원에게 브리핑 시 해당 섹션은 "아직 정의되지 않음" 으로 표시된다.)
- `y`: 빈 템플릿 생성 — 아래 구조의 모든 값을 `[TBD]` 로.

### 감지 성공 시

1. Color.kt 또는 `.colorset` 에서 색상 토큰 자동 추출
2. Theme.kt 에서 typography / shape 추출
3. **예시 생성형 대화** — 아래 공통 출력 형식으로 질문한다.

**공통 출력 형식 (디자인 원칙 1~3 개):**
```
[디자인 원칙 1~3 개]

레포 스캔 결과 (가정):
  - 색상 시스템: {Material3 / 커스텀 팔레트 / 단색 기반 등}
  - typography: {MaterialTypography / 커스텀 등}
  - shape: {rounded 수준}

아래 중 가깝거나 직접 입력해주세요:
  1) {원칙 예시 1} (매칭: {근거})
  2) {원칙 예시 2} (매칭: {근거})
  3) {원칙 예시 3} (매칭: {근거})
  4) 직접 입력

번호 선택 또는 직접 입력 (건너뛰기 시 Enter → [TBD]):
```

**원칙 예시 (스캔 매칭):**

| 감지 패턴 | 원칙 예시 |
|----------|---------|
| Material3 색상 토큰 | "Material3 표준 준수, 커스텀 컬러 최소화" |
| colorScheme 에 light / dark 둘 다 정의 | "다크모드 우선 설계" |
| rounded shape 토큰 존재 | "부드러운 shape 기반, 각진 UI 지양" |
| 고정된 typography scale | "Typography 는 토큰만 사용, inline fontSize 지정 금지" |
| 커스텀 팔레트 | "브랜드 컬러 강조, 배경은 최소화된 뉴트럴" |

**공통 출력 형식 (컴포넌트 커스터마이징 규칙):**
```
[컴포넌트 커스터마이징 규칙]

아래 중 가깝거나 직접 입력해주세요:
  1) {규칙 예시 1} (매칭: {근거})
  2) {규칙 예시 2} (매칭: {근거})
  3) 직접 입력

번호 선택 또는 직접 입력 (건너뛰기 시 Enter → [TBD]):
```

**규칙 예시 (스캔 매칭):**

| 감지 패턴 | 규칙 예시 |
|----------|---------|
| Card composable 사용 | "Card 는 elevation 0, rounded 12dp 고정" |
| M3 Button 사용 | "Button 은 M3 Variant 만 사용 (Filled / Outlined / Text)" |
| 커스텀 Icon | "Icon 은 20dp / 24dp 두 사이즈만 사용" |

스캔 매칭 실패 시 일반 템플릿, `(일반 템플릿)` 표기.

**건너뛰기**: 빈 줄 / `건너뛰기` 등 → `[TBD]`.

### 출력 템플릿

```markdown
# UI 디자인 가이드

## 원칙
{수집된 원칙 또는 [TBD]}

## 색상
{자동 추출된 색상 토큰 표}

## 컴포넌트
{주요 컴포넌트 스타일 또는 [TBD]}

## AI 슬롭 금지 (하지 마라)
- `backdrop-filter: blur()` — glass morphism
- gradient text (배경 그라데이션 텍스트)
- "Powered by AI" 배지
- box-shadow 글로우 애니메이션
- 보라/인디고 브랜드 색상 ("AI = 보라색" 클리셰)
- 배경 gradient orb (blur-3xl 원형)
```

---

## 6. docs/WORKFLOW.md 생성 (정적 템플릿)

아래 템플릿을 **그대로** 파일에 기록한다. 대화 없음.

```markdown
# 업무 워크플로우

## 우리 팀은 Claude Code 를 이렇게 씁니다

### 기능 개발
/feature <기획서 PDF 또는 설명>
→ 기획서 분석 → brainstorming → feature-plan.md 생성
→ /phase 1 → /phase 2 → ... 단계별 실행
  (각 Task: subagent writer + 테스트 1 회, Phase 완료 후 reviewer)

### 버그 수정
/bugfix <에러 로그 / 설명 / 스크린샷>
→ 유형 분류 (로직 / UI)
→ 로직: systematic-debugging → 복잡도 판단 → TDD 수정
→ UI: 영향 컴포넌트 특정 → 스냅샷 테스트 → 시각 검증

### 보조 도구
- /phase: plan.md 를 단계별로 실행

## 규칙
- 모든 스킬은 docs/ 가드레일을 읽고 동작 (CLAUDE.md 의 @ 참조)
- docs/ 변경 시 팀 공유 필수

## 참고
- 플러그인 README.md
```

---

## 생성 완료 후

아래 리포트를 출력한다:

```
## Onboard 완료 리포트 (생성 모드)
- 플랫폼: {Android / iOS}
- 생성 파일:
  - CLAUDE.md
  - docs/PRD.md
  - docs/ARCHITECTURE.md
  - docs/ADR.md
  - docs/UI_GUIDE.md (또는 생략)
  - docs/WORKFLOW.md
- 스킵 파일 (이미 존재): {Case 2 에서만 해당}

다음 단계:
  git add {생성 파일 목록}
  git commit -m "feat: add harness documents via /onboard"

이후 /feature, /bugfix 등을 실행하면 자동으로 하네스 가드레일이 적용됩니다.
```

> `{생성 파일 목록}` 은 런타임에 실제로 생성된 파일 경로들(예: `CLAUDE.md docs/PRD.md docs/ARCHITECTURE.md docs/ADR.md docs/WORKFLOW.md`) 로 Claude 가 치환해 출력한다.
