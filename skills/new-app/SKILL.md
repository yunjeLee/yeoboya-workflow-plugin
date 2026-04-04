# New App Skill — 새 앱 생성

기획서(PDF)를 기반으로 새 앱 프로젝트를 스캐폴딩한다.

## 트리거
- `/new-app 기획서.pdf`

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
- 각 모듈/디렉토리 생성 후 빌드 확인을 수행한다.

**Android 빌드 확인:**
```bash
./gradlew assembleDebug
```

**iOS 빌드 확인:**
```bash
xcodebuild build -scheme <SchemeName: 프로젝트 스킴명으로 교체> -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 완료 리포트 형식

```
## New App 완료 리포트
- 플랫폼: Android / iOS / Both
- 앱 이름: [이름]
- 생성된 모듈/구조: [목록]
- 빌드 결과: SUCCESS
```
