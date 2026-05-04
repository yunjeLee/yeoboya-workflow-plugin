# module-detect 모듈

호출자(`skills/harness-map/SKILL.md`) 가 Read tool 로 읽고 그대로 따른다.
이 모듈은 플랫폼별로 모듈 후보를 감지하고, 각 모듈의 메타정보를 수집하고, Y/N 추천 디폴트를 결정하는 절차를 정의한다.

---

## 진입 인터페이스

호출자는 이 모듈에 인자 없이 진입한다.
`PLATFORM` 변수(`Android` / `iOS` / 그 외) 는 호출자가 사전에 결정해서 들고 있다 — 본 모듈은 이를 그대로 신뢰한다 (호출자 책임).

본 모듈의 출력은 다음 두 가지다:

- `modules`: 감지된 모듈 목록. 각 항목은 `{ name, path, file_count, has_namespace, depends_on, dependents, has_readme, recommend }` 형태.
- `recommend` 는 `Y` 또는 `N` (디폴트값일 뿐, 사용자가 [Y/n] 으로 뒤집을 수 있음).

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

---

## 추천 휴리스틱 (Y/N 디폴트)

각 모듈의 메타정보를 보고 `recommend` 디폴트값을 정한다.

### 권장(Y) 신호

다음 중 **2 개 이상** 만족 시 `Y`:

- `file_count >= 10`
- `has_namespace == true`
- `dependents.length > 0` (이 모듈에 의존하는 다른 모듈이 1 개 이상 존재)
- `has_readme == true`

### 비권장(N) 신호

다음 중 **2 개 이상** 만족 시 `N`:

- `file_count < 5`
- 모듈명이 정규식 `^.+-(util|utils|common|core|helpers|ext)$` 로 매칭 (대소문자 무시, gradle 콜론 표기일 경우 마지막 세그먼트만 비교 — 예: `:core:common` 의 `common`)
- `dependents.length == 0`

### 충돌 해결

- Y 와 N 양쪽이 모두 발동하면 **Y 우선**.
- 어느 쪽도 발동 안 하면 안전하게 `Y` (의심스러우면 포함이 디폴트).

### 사용자 오버라이드

추천은 **디폴트일 뿐** 이다. 호출자는 각 모듈을 사용자에게 노출할 때 `[Y/n]` (Y 디폴트) 또는 `[y/N]` (N 디폴트) 형태로 물어 사용자가 한 글자 입력으로 뒤집을 수 있게 한다.
