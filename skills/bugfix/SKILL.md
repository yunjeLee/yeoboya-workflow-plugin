# Bugfix Skill — 오류 수정

버그 설명 / 스크린샷 / 에러 로그를 입력받아 수정을 수행한다.

## 트리거
- `/bugfix [버그 설명 또는 에러 로그]`

---

## Step 1: 플랫폼 자동 감지

프로젝트 루트에서 아래 파일을 스캔한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문
```

---

## Step 2: 버그 유형 분류 (Router)

입력된 버그 설명을 분석해 유형을 판별한다.

**로직 / 크래시 버그 판별 기준:**
- 에러 로그 / 스택 트레이스 포함
- 특정 조건에서 크래시 발생
- 데이터 처리 결과가 잘못됨
- 상태 관리 오류

**UI 버그 판별 기준:**
- 레이아웃 깨짐, 색상 오류, 여백 문제
- 애니메이션 / 전환 이상
- 특정 상태에서 UI가 잘못 표시됨
- 스크린샷으로 재현 가능한 문제

판별 불가 시: "로직 버그인가요, UI 표시 문제인가요?" 질문

---

## Step 3-A: 로직 / 크래시 버그 수정 플로우

### 3-A-1. 원인 분석 (systematic-debugging)
`superpowers:systematic-debugging` 스킬을 호출한다.

### 3-A-2. 테스트로 재현 후 수정 (test-driven-development)
`superpowers:test-driven-development` 스킬을 호출한다.
- 버그를 재현하는 실패 테스트를 먼저 작성한다.
- 테스트를 통과하는 최소 수정을 적용한다.

플랫폼별 테스트 명령어:
- Android: `./gradlew test`
- iOS: `xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'`

### 3-A-3. 검증
`superpowers:verification-before-completion` 스킬을 호출한다.

---

## Step 3-B: UI 버그 수정 플로우

### 3-B-1. 영향 범위 특정
버그가 발생하는 컴포넌트를 특정한다.
- Android: 영향받는 Composable 함수명 및 파일 경로
- iOS: 영향받는 View / ViewController 및 파일 경로

### 3-B-2. 스냅샷 테스트로 재현
플랫폼별 스냅샷 테스트 도구로 버그 상태를 캡처한다.

**Android (Paparazzi):**
```kotlin
@Test
fun `버그 재현 - [증상 설명]`() {
    paparazzi.snapshot {
        // 버그가 발생하는 상태로 컴포넌트 렌더링
        BuggyComposable(state = BugState(...))
    }
}
```

**iOS (swift-snapshot-testing):**
```swift
func test_버그재현_증상설명() {
    let vc = BuggyViewController()
    vc.configure(with: bugState)
    assertSnapshot(matching: vc, as: .image)
}
```

### 3-B-3. 수정 후 시각적 검증
수정 후 스냅샷을 갱신하고 변경 전/후를 비교한다.

```bash
# Android: 스냅샷 갱신
./gradlew recordPaparazziDebug

# iOS: 스냅샷 갱신
swift test --filter SnapshotTests -- -record
```

### 3-B-4. 검증
`superpowers:verification-before-completion` 스킬을 호출한다.

---

## 완료 리포트 형식

```
## Bugfix 완료 리포트
- 플랫폼: Android / iOS
- 버그 유형: 로직 / UI
- 증상: [설명]
- 원인: [분석 결과]
- 수정 내용: [변경 파일 및 내용]
- 테스트 결과: PASS
```
