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

## Step 1: 플랫폼 선택

신규 프로젝트이므로 자동 감지 불가. 직접 선택을 받는다.

```
"Android(Kotlin/Compose)와 iOS(Swift/SwiftUI) 중 어떤 플랫폼인가요?
또는 둘 다 생성하시겠습니까?"
```

---

## Step 2: 앱 구조 설계 (brainstorming)

`superpowers:brainstorming` 스킬을 호출한다.
- 기획서를 분석해 필요한 화면, 기능, 아키텍처를 결정한다.
- Android: Clean Architecture + Multi-module + MVI
- iOS: Clean Architecture + MVVM

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
- 생성된 모듈/구조: [목록]
- 빌드 결과: SUCCESS
```

**생성된 모듈/구조 예시:**
- **Android:** :app, :feature:home, :domain, :data, :core:common, :core:designsystem
- **iOS:** App/, Features/Home/, Domain/, Data/, Core/
