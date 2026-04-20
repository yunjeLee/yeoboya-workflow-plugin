---
name: bugfix
description: "버그 설명, 에러 로그, 스크린샷 또는 텍스트 설명을 기반으로 버그를 수정한다. /bugfix, 버그, 크래시, 에러, 오류, 앱이 죽음, 동작 안 함 요청 시 반드시 사용한다. PDF나 로그 없이 말로 설명해도 동일하게 동작한다."
---

# Bugfix Skill — 오류 수정

버그 설명 / 스크린샷 / 에러 로그 또는 텍스트 설명을 입력받아 수정을 수행한다.

## 트리거
- `/bugfix [버그 설명 또는 에러 로그]` — 텍스트로 직접 설명
- `/bugfix` 후 스크린샷 첨부 — 시각적 버그 보고

---

## 공통 지침 참조
- **가장 먼저**: `shared/workflow.md`를 Read tool로 읽고 **하네스 문서 부재 감지** 섹션을 실행한다. 응답에 따라 진행 여부를 결정한다.

---

## Step 0: 작업 격리 (선택)

브랜치 격리가 필요하다면 `superpowers:using-git-worktrees` 스킬을 먼저 호출한다.

---

## Step 1: 플랫폼 자동 감지

`shared/workflow.md`를 Read tool로 읽고 **플랫폼 자동 감지** 섹션의 지침을 따른다.

---

## Step 2: 버그 유형 분류

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

### 3-A-1. 원인 분석
`superpowers:systematic-debugging` 스킬을 호출한다.

### 3-A-2. 복잡도 판단

원인 분석 결과를 바탕으로 수정 범위를 확인한다.

**단순 수정** (1~2개 파일, 명확한 원인):
→ Step 3-A-3으로 바로 진행한다.

> **복잡도 재판정**: 수정 중 3 번째 파일을 건드려야 하는 상황이 발생하면 즉시 작업을 중단하고 `superpowers:writing-plans` 로 전환해 복잡한 수정 경로로 재진입한다.

**복잡한 수정** (3개 이상 파일, 여러 레이어에 걸침):
→ `superpowers:writing-plans` 스킬을 호출해 수정 계획을 작성한다.
→ `shared/workflow.md`를 Read tool로 읽고 **계획 저장 및 실행 안내** 섹션의 지침을 따른다.

### 3-A-3. 테스트로 재현 후 수정
`superpowers:test-driven-development` 스킬을 호출한다.
- 버그를 재현하는 실패 테스트를 먼저 작성한다.
- 테스트를 통과하는 최소 수정을 적용한다.

플랫폼별 테스트 명령어:
- Android: `./gradlew test`
- iOS: `xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'`

### 3-A-4. 검증
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

**순서 중요.** 수정 직후 곧바로 record 를 실행하면 버그 상태가 새 baseline 으로 승격될 위험이 있다. 아래 순서를 지킨다.

1. 수정 후 테스트를 실행만 하고 record 는 하지 않는다. (Paparazzi / swift-snapshot-testing 모두 verify 모드가 기본)
2. 실패한 스냅샷의 diff 이미지를 육안으로 확인한다. 의도한 수정 결과가 맞는지 판단한다.
3. 사용자에게 "이 결과로 baseline 을 갱신할까요? (y / n)" 확인한다.
4. `y` 응답 시에만 아래 record 명령을 실행한다.

```bash
# Android: 스냅샷 갱신 (3번 단계 승인 후)
./gradlew recordPaparazziDebug

# iOS: 스냅샷 갱신 (3번 단계 승인 후)
swift test --filter SnapshotTests -- -record
```

### 3-B-4. 검증
`superpowers:verification-before-completion` 스킬을 호출한다.

---

## Step 4: 브랜치 마무리

수정이 완료되면 `superpowers:finishing-a-development-branch` 스킬을 호출한다.

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
