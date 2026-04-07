---
name: new-app
description: "기획서(PDF) 또는 텍스트 설명을 기반으로 새 Android/iOS 앱 프로젝트를 스캐폴딩한다. /new-app, 새 앱 만들기, 프로젝트 생성, 앱 처음부터 만들기 요청 시 반드시 사용한다. PDF 없이 앱 아이디어를 말로 설명해도 동일하게 동작한다."
---

# New App Skill — 새 앱 생성

기획서(PDF) 또는 텍스트 설명을 기반으로 새 앱 프로젝트를 스캐폴딩한다.

## 트리거
- `/new-app 기획서.pdf` — PDF 기획서로 시작
- `/new-app [앱 아이디어 설명]` — 텍스트로 직접 설명

---

## 공통 지침 참조
- 시작 시: `shared/prompt-refiner.md`를 Read tool로 읽고 지침을 따른다.
- UI 작업 감지 시: `shared/ui-review.md`를 Read tool로 읽고 지침을 따른다.

---

## Step 1: 플랫폼 선택

신규 프로젝트이므로 자동 감지 불가. 직접 선택을 받는다.

```
"Android(Kotlin/Compose)와 iOS(Swift/SwiftUI) 중 어떤 플랫폼인가요?
또는 둘 다 생성하시겠습니까?"
```

---

## Step 1.5: 아키텍처 & 디자인 패턴 선택

플랫폼 선택 직후 아래 두 항목을 필수로 선택받는다.
선택 결과는 `.yeoboya-state.json`에 저장해 이후 모든 단계에서 참조한다.

### 아키텍처 선택 (필수)

**Android:**
```
1. Clean Architecture (추천)
2. MVC
3. MVVM
4. 직접 입력
```

**iOS:**
```
1. Clean Architecture (추천)
2. MVC
3. VIPER
4. 직접 입력
```

### 디자인 패턴 선택 (필수)

**Android:**
```
1. MVI + StateFlow (추천)
2. MVVM + LiveData
3. MVVM + StateFlow
4. 직접 입력
```

**iOS:**
```
1. MVVM + Combine (추천)
2. MVP
3. Redux
4. 직접 입력
```

### 추가 옵션 (선택사항)

아래 항목은 선택사항이다. 입력하지 않으면 선택한 아키텍처에 맞게 Claude가 추천한다.

- 멀티모듈 여부 (Android만 해당)
- 모듈 분리 전략
- 기타 기술 스택

### 상태 저장

선택 완료 후 `.yeoboya-state.json`에 기존 필드를 유지하면서 병합 저장한다.

```json
{
  "architecture": "[선택한 아키텍처]",
  "designPattern": "[선택한 디자인 패턴]",
  "additionalOptions": {}
}
```

---

## Step 2: 앱 구조 설계 (brainstorming)

`superpowers:brainstorming` 스킬을 호출한다.
- 기획서를 분석해 필요한 화면, 기능, 아키텍처를 결정한다.
- Step 1.5에서 저장한 `.yeoboya-state.json`의 `architecture` 및 `designPattern` 값을 반드시 참조한다.
- 해당 값에 맞는 모듈 구조와 설계 방향을 결정한다.

---

## Step 3: 스캐폴딩 계획 (writing-plans)

`superpowers:writing-plans` 스킬을 호출한다.

**Android 기본 모듈 구조:**
```
:app
:feature:<feature_name>
:domain
:data
:core:common
:core:designsystem
```

**iOS 기본 구조:**
```
Sources/
├── App/
├── Features/
├── Domain/
├── Data/
└── Core/
```

---

## Step 4: 프로젝트 생성 (executing-plans)

`superpowers:executing-plans` 스킬을 호출한다.
- `agents/writer.md` 기반 subagent가 프로젝트를 생성한다.

**Subagent가 수행하는 작업:**
- 모듈/디렉토리 생성
- **Android:** build.gradle.kts, settings.gradle.kts, 최소 동작 코드(Application 클래스 등) 작성
- **iOS:** Package.swift 또는 Xcode 프로젝트 파일, 최소 동작 AppDelegate/App 파일 작성
- 각 모듈 생성 후 즉시 빌드 확인 수행

**Android 빌드 확인:**
```bash
./gradlew assembleDebug
```

**iOS 빌드 확인:**
```bash
xcodebuild build -scheme <SchemeName: 프로젝트 스킴명으로 교체> -destination 'platform=iOS Simulator,name=iPhone 15'
```

**빌드 실패 시:** 에러 내용을 사용자에게 보고하고 계속 진행 여부를 확인한다.

---

## 완료 리포트 형식

```
## New App 완료 리포트
- 플랫폼: Android / iOS / Both
- 앱 이름: [이름]
- 아키텍처: [선택한 아키텍처]
- 디자인 패턴: [선택한 디자인 패턴]
- 생성된 모듈/구조: [목록]
- 빌드 결과: SUCCESS
```

**생성된 모듈/구조 예시:**
- **Android:** :app, :feature:home, :domain, :data, :core:common, :core:designsystem
- **iOS:** App/, Features/Home/, Domain/, Data/, Core/
