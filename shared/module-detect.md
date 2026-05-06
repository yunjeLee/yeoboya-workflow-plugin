# module-detect 모듈

호출자(`skills/harness-module/SKILL.md`) 가 Read tool 로 읽고 그대로 따른다.
이 모듈은 플랫폼별로 모듈 후보를 감지하고, 각 모듈의 메타정보를 수집하고, Y/N 추천 디폴트를 결정하는 절차를 정의한다.

---

## 진입 인터페이스

호출자는 이 모듈에 인자 없이 진입한다.
`PLATFORM` 변수(`Android` / `iOS` / 그 외) 는 호출자가 사전에 결정해서 들고 있다 — 본 모듈은 이를 그대로 신뢰한다 (호출자 책임).

본 모듈의 출력은 다음 두 가지다:

- `modules`: 감지된 모듈 목록. 각 항목은 `{ name, path, file_count, has_namespace, depends_on, dependents, has_readme, commit_count_3m, legacy_pair, score, recommend, reason }` 형태.
- `recommend` 는 `Y` 또는 `N` (디폴트값일 뿐, 사용자가 [Y/n] 으로 뒤집을 수 있음).
- `score` 는 0~8점 정수, `reason` 은 추천 근거 한 줄 문자열.

---

## 플랫폼별 모듈 감지

### Android

1. 프로젝트 루트의 `settings.gradle.kts` 가 존재하면 Read. 없으면 `settings.gradle` 을 Read.
2. 본문에서 `include(...)` 호출을 다음 정규식으로 추출한다:
   - `include\s*\(\s*"(:[^"]+)"\s*\)` (Kotlin DSL, Groovy quoted form)
   - `include\s+":[^"]+"` (Groovy 무괄호 form)
3. 추출한 모듈 ID(예: `:feature:home`) 를 그대로 `name` 으로 사용한다 (leading colon 포함, gradle 표기 유지). 디렉토리 경로는 leading colon 을 제거하고 남은 콜론을 `/` 로 치환해 별도 `path` 필드로 둔다.
   - `:feature:home` → name `:feature:home`, path `feature/home`
   - `:app` → name `:app`, path `app`
4. 추출된 path 가 실제 디렉토리로 존재하지 않으면 제외한다.

### iOS

다음 우선순위로 한 가지 모드만 선택한다.

**1순위 — Tuist 모드**

- 루트 또는 1 depth 에 `Project.swift` 존재 시 Tuist 모드로 본다. `Tuist/Project.swift` 도 함께 확인한다.
- 발견된 `Project.swift` 들을 모두 Read 해서 `Project(name: "...", targets: [ ... ])` 안의 `Target(name: "..."...)` 또는 `.target(name: "...")` 호출에서 타겟명을 추출한다.
- 각 타겟의 path 는 같은 `Project.swift` 의 `sources:` / `path:` 인자에서 추출한다. 명시되지 않은 경우 `{타겟명}/` 가 존재하면 그것을 사용. 없으면 `Sources/{타겟명}/` 를 사용. 둘 다 없으면 `file_count = 0`, `dependents = []` 로 두고 휴리스틱에 위임한다.

**2순위 — SwiftPM 모드**

- Tuist 가 아니고 루트에 `Package.swift` 존재 시 SwiftPM 모드.
- Read 해서 `targets: [ ... ]` 배열에서 `.target(name: "...")`, `.executableTarget(name: "...")`, `.testTarget(name: "...")` 의 name 을 추출한다. **testTarget 은 후보에서 제외한다.** 테스트 모듈은 모듈 맵 대상이 아니다.
- 각 타겟 path 는 `path: "..."` 인자가 있으면 그 값, 없으면 SwiftPM 기본 규칙 `Sources/{타겟명}/`.

**3순위 — xcodeproj 모드**

- 위 둘 모두 부재하고 `*.xcodeproj` 디렉토리가 존재하면 xcodeproj 모드.
- `*.xcodeproj/project.pbxproj` 를 Read 해서 `PBXNativeTarget` 섹션의 `name = ...;` 또는 `name = "...";` 라인에서 타겟명을 추출한다.
- 정규식 예: `/\* Begin PBXNativeTarget section \*/[\s\S]*?/\* End PBXNativeTarget section \*/` 블록 안에서 `name\s*=\s*"?([^";]+)"?\s*;` 매칭.
- 정규식 추출이 실패하거나 결과가 비어 있으면 사용자에게 한 번 묻는다:
  ```
  xcodeproj 에서 타겟을 자동으로 못 찾았습니다.
  모듈/타겟 디렉토리 glob 을 직접 입력해 주세요. (예: Sources/* 또는 Modules/*)
  ```

### 일반 (General)

- `PLATFORM` 이 Android / iOS 둘 다 아니거나, 또는 Android / iOS 모드로 진입했다가 감지된 모듈 수가 0 으로 끝났을 때 일반 모드로 fallback 한다.
- 일반 모드로 들어온 시점부터 메타 수집(특히 `has_namespace`) 은 일반 모드 룰을 따른다.
- 사용자에게 1 회만 묻는다:
  ```
  이 프로젝트의 모듈 디렉토리 glob 을 입력하세요. (예: src/* 또는 packages/*)
  ```
- 답변을 Glob 으로 실행해 디렉토리 목록을 수집한다. 각 항목의 디렉토리명을 모듈 name 으로 사용한다.

---

## 모듈 메타정보 수집

위에서 만든 모듈 목록의 각 모듈에 대해 다음 4 개를 수집한다.

### file_count

- Android: `{path}/**/*.kt` 를 Glob 한 결과 개수.
- iOS: `{path}/**/*.swift` 를 Glob 한 결과 개수.
- 일반: 사용자가 입력한 glob 으로 들어온 디렉토리 내 파일 전체를 `{path}/**/*` 로 Glob 한 결과 개수.

### has_namespace

- Android:
  - `{path}/build.gradle.kts` 가 존재하면 Read, 없으면 `{path}/build.gradle` Read.
  - `namespace\s*=\s*"([^"]+)"` 매칭이 있으면 `true`, 없으면 `false`.
- iOS:
  - 모듈명에 `.` 가 포함되거나 (예: `com.example.feature`), Tuist `Project.swift` / SwiftPM `Package.swift` 에서 해당 타겟에 `bundleId` / `productName` 같은 명시적 식별자가 정의돼 있으면 `true`. 그 외는 `false`.
- 일반: 항상 `false` 로 둔다 — 디렉토리명만으로는 namespace 판정 신호가 약하다. 휴리스틱은 나머지 3 개 신호 (`file_count` / `dependents` / `has_readme`) 로 판정한다.

### depends_on (정방향)

이 모듈이 직접 의존하는 다른 모듈 ID 배열. 자기 자신의 빌드 정의를 한 번만 읽는다.

- Android: 이 모듈의 `build.gradle(.kts)` 에서 `implementation\s*\(\s*project\s*\(\s*"(:[^"]+)"\s*\)\s*\)` (그리고 `api(project(...))`, `testImplementation(project(...))` 변종) 매칭으로 추출한 모듈 ID 목록.
- iOS:
  - Tuist: 이 타겟의 `Target(... dependencies: [ .target(name: "...") ])` 만 사용.
  - SwiftPM: 이 타겟의 `dependencies: [ .target(name: "...") ]` 만 사용.
- 일반: 모듈 간 의존성 자동 감지 불가 → 빈 배열 (`[]`).

### dependents (역방향)

이 모듈을 다른 모듈이 참조하는 빈도. 즉, 다른 모듈의 빌드 정의를 모두 훑어서 이 모듈을 의존성으로 선언한 모듈 목록을 만든다.

- Android: 전체 모듈의 `build.gradle(.kts)` 를 순회하며 위 정규식으로 매칭을 모은 뒤, 매칭의 인자가 이 모듈 ID 와 일치하면 그 소스 모듈을 `dependents` 에 추가.
- iOS:
  - Tuist: 모든 `Project.swift` 를 순회. `Target(...)` 의 `dependencies` 가 이 타겟을 참조하는 경우.
  - SwiftPM: `Package.swift` 의 모든 타겟의 `dependencies` 가 이 타겟을 참조하는 경우.
- 일반: 모듈 간 의존성 자동 감지 불가 → 빈 배열 (`[]`).

> 두 방향은 같은 정규식을 한 번의 빌드 파일 순회로 함께 모아 동시에 채워도 된다.

### has_readme

- 모듈 디렉토리(`{path}`) 에 `README.md` 가 존재하면 `true`, 아니면 `false`. 대소문자만 다른 변형(`Readme.md`, `readme.md`) 도 동등 취급.

### commit_count_3m

최근 3 개월 동안 이 모듈 안의 소스 파일이 변경된 git 커밋 수.

- Bash tool 로 다음 형태의 커맨드를 실행한다:
  - macOS: `git log --since="$(date -v-3m +%Y-%m-%d)" --name-only --pretty=format: -- "{path}/" | grep -c "{ext}"`
  - Linux: `git log --since="$(date -d '-3 months' +%Y-%m-%d)" --name-only --pretty=format: -- "{path}/" | grep -c "{ext}"`
- 확장자 패턴 (`{ext}`):
  - Android: `\.kt$\|\.java$`
  - iOS: `\.swift$`
  - 일반: `.` (모든 파일 카운트)
- git 저장소가 아니거나 커맨드 실패 시 `0` 으로 둔다 (휴리스틱은 다른 신호로 작동).

### legacy_pair

같은 책임을 가진 레거시/신규 모듈이 함께 존재하는지 여부 (boolean). AI 가 가장 헷갈리는 케이스를 잡아내기 위한 신호다.

전체 modules 목록을 모두 모은 다음 마지막 단계에서 한 번에 계산한다 (개별 모듈 단위로는 판정 불가).

판정 절차:

1. 각 모듈명에서 마지막 콜론 세그먼트만 추출 (예: `:core:core_model` → `core_model`, `:core:model` → `model`).
2. 그 세그먼트에 정규식 `^core[_-](.+)$` 매칭하면 base 는 캡처 그룹 (예: `core_model` → `model`, `core-data` → `data`). 매칭 안 되면 base 는 세그먼트 자체.
3. 같은 base 를 가진 모듈이 2 개 이상 존재하면 그 모듈들 모두 `legacy_pair = true`. 그 외는 `false`.

예:
- `:core:model` (base=`model`) + `:core:core_model` (base=`model`) → 둘 다 `true`
- `:core:remote` + `:core:core_remote` → 둘 다 `true`
- `:feature:home` 단독 → `false`

---

## 추천 휴리스틱 (점수 기반)

각 모듈의 메타정보를 보고 `score` (0~8점), `recommend` (`Y` / `N`), `reason` (추천 근거 한 줄) 을 계산한다.

부족 지식(Tribal Knowledge) 이 있을 가능성이 높은 모듈을 잡는 것이 목적이다. 핵심 신호 2 개와 보조 신호 1 개로 점수를 매긴다.

### 점수 계산

**핵심 1 — 수정 빈도** (`commit_count_3m`)
미래에 AI 가 자주 건드릴 모듈일수록 CLAUDE.md ROI 가 즉시 발생한다.

- `>= 10` → 4 점
- `5 ~ 9` → 3 점
- `2 ~ 4` → 2 점
- `0 ~ 1` → 0 점

**핵심 2 — 팬인** (`dependents.length`)
다른 모듈이 많이 의존하는 모듈은 잘못 건드리면 파장이 크다. 함정 문서화 가치가 크다.

- `>= 5` → 3 점
- `3 ~ 4` → 2 점
- `1 ~ 2` → 1 점
- `0` → 0 점

**보조 — 레거시/신규 혼재** (`legacy_pair`)
같은 책임의 모듈이 두 개 이상 공존하면 AI 가 어느 쪽에 코드를 넣어야 할지 판단할 수 없다.

- `true` → +1 점
- `false` → +0 점

총점 범위: 0 ~ 8 점.

### 추천 결정 (recommend)

- `score >= 5` → `Y`
- `score < 5` → `N`

### 무조건 N (점수 무관)

다음 중 하나라도 해당하면 점수와 무관하게 `recommend = N`. 단순하거나 거의 변하지 않는 모듈에 CLAUDE.md 를 만드는 것은 유지보수 부담만 늘린다.

- `file_count < 10` (코드를 읽으면 바로 이해되는 단순 모듈)
- `commit_count_3m == 0` 이면서 `dependents.length == 0` (안정적이고 누구도 의존하지 않는 모듈)

### reason 생성

추천 근거를 한 줄로 만든다. 점수에 기여한 신호만 골라 콤마로 연결한다. 무조건 N 룰로 걸러진 경우 사유를 명시한다.

예시:
- `수정 12회, 팬인 5개, 레거시 혼재` (Y 추천, 점수 8)
- `수정 8회, 팬인 1개` (Y 추천, 점수 4 → 컷오프 미달이지만 비슷)
- `팬인 3개, 레거시 혼재` (Y 추천, 점수 3 → 컷오프 미달)
- `파일 3개 — 단순 모듈` (N 추천, 무조건 N)
- `수정 0회 + 의존받지 않음 — 안정 모듈` (N 추천, 무조건 N)

### 사용자 오버라이드

추천은 **디폴트일 뿐** 이다. 호출자는 각 모듈을 사용자에게 노출할 때 `[Y/n]` (Y 디폴트) 또는 `[y/N]` (N 디폴트) 형태로 물어 사용자가 한 글자 입력으로 뒤집을 수 있게 한다.

### Anchoring Bias 방지

호출자는 추천 표를 보여준 뒤 사용자에게 한 가지 추가 질문을 던진다 — *"이 리스트에 빠진 모듈 중 자주 막혔거나 다른 사람한테 물어봤던 모듈이 있나요?"*. 데이터로 못 잡는 부족 지식 신호를 사람으로부터 받아내기 위함이다.
