# architecture 모듈

호출자 (`/harness`, `/harness-edit`) 가 Read tool 로 읽고 지침을 따른다. 자동 스캔 100%, 대화 없음.

## 대상 파일

`docs/ARCHITECTURE.md`

## 사전 스캔

### Android 절차

1. `settings.gradle(.kts)` Read → `include(":xxx")` 패턴으로 모듈 목록 추출.
2. 각 모듈의 소스 디렉토리 Glob 으로 패키지 트리(2 레벨) 추출:
   - 먼저 모듈 이름(`:feature:home`) 의 `:` 를 `/` 로 치환해 경로 생성 (`feature/home`).
   - Glob 우선순위: `{모듈 경로}/src/main/java/**/*.kt` → `{모듈 경로}/src/main/kotlin/**/*.kt`.
   - 둘 다 비어있으면 `{모듈 경로}/**/*.kt` 로 fallback.
3. 각 모듈의 `build.gradle(.kts)` Read → `dependencies { ... implementation(project(":xxx")) }` 패턴으로 모듈 간 관계 확인.
4. 사용 라이브러리로부터 패턴 추정:
   - `hilt-android` 또는 `dagger.hilt.*` → DI = Hilt.
   - `androidx.compose.*` → UI 시스템 = Jetpack Compose.
   - `kotlinx.coroutines.*` + `flow` → 상태 관리 = Flow / StateFlow.
   - `androidx.lifecycle.*` → lifecycle-aware.
5. Clean Architecture / MVI 여부:
   - 모듈 이름에 `:domain`, `:data`, `:feature` 가 있으면 Clean.
   - `reduce`, `Intent`, `SideEffect` 같은 키워드가 있으면 MVI.
   - 확실하지 않으면 [TBD] 처리.

### iOS 절차

1. `Package.swift` Read → `targets: [ .target(name: "xxx") ]` 에서 타겟 목록 추출.
2. `*.xcodeproj/project.pbxproj` Read → `PBXGroup` 섹션에서 폴더 구조 추출.
3. `Podfile` 또는 `Cartfile` Read → 외부 의존성 목록.
4. 파일 구조로부터 패턴 추정 (`Sources/Features/`, `Sources/Domain/`, `Sources/Data/` 존재 → Clean Architecture).

### 결과 형식

- 모듈/타겟 트리 + 각 항목의 1줄 역할 표시.
- 사용 라이브러리 → 패턴 매핑 (DI, UI 시스템, 상태 관리, lifecycle).
- 아키텍처 패턴 추정 결과 (Clean / MVI / 기타).

## 섹션 목록

| 섹션 ID | 헤더 | 타입 | 질문 수 |
|--------|-----|-----|--------|
| s1 | `## 디렉토리 구조` | 자동 | 0 |
| s2 | `## 패턴` | 자동 | 0 |
| s3 | `## 데이터 흐름` | 자동 (추정 불가 시 [TBD]) | 0 |
| s4 | `## 상태 관리` | 자동 | 0 |

## 섹션별 생성 로직

### s1: 디렉토리 구조

실제 스캔 결과 트리. 각 모듈/타겟 오른쪽에 1 줄 역할 표시. 도출 불가 시 `[TBD]`.

### s2: 패턴

- 아키텍처: Clean Architecture / MVC / MVVM / 직접 입력 / [TBD]
- 디자인 패턴: MVI / MVVM / Redux / [TBD]
- UI 시스템: Jetpack Compose / XML / SwiftUI / UIKit / [TBD]

### s3: 데이터 흐름

UI → ViewModel → UseCase → Repository → DataSource 형태의 다이어그램. 모듈 구조에서 역추출 불가하면 `[TBD]`.

### s4: 상태 관리

StateFlow / LiveData / Combine Publisher / [TBD]

## 출력 템플릿

````markdown
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
````
