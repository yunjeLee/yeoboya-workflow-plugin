# Auto-Fix Loop

이 지침을 Read tool로 읽은 스킬은 아래 순서를 따른다.

---

## 플랫폼 감지

프로젝트 루트에서 아래 파일을 스캔해 테스트 명령어를 결정한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
  TEST_CMD=./gradlew test

*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
  TEST_CMD=xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'

둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문 후 결정
```

---

## 루프 실행

아래 루프를 최대 3회 반복한다. (RETRY=0 으로 시작)

### 1. 테스트 실행

Bash tool로 TEST_CMD를 실행한다.

**성공 시 (exit code 0):**
아래 리포트를 출력하고 루프를 종료한다.

```
[Auto-Fix 완료]
- 시도 횟수: {RETRY+1}/3
- 수정한 파일: {수정한 파일 목록. 없으면 "없음"}
- 테스트 결과: PASS
```

**실패 시 (exit code ≠ 0):**
stdout + stderr 전체를 캡처해 다음 단계로 이동한다.

### 2. 에러 분석 및 수정 (실패 시)

캡처한 에러 메시지를 분석한다.

1. 에러가 발생한 파일과 라인을 특정한다.
2. 원인을 판단한다.
3. Read tool로 해당 파일을 읽고 Edit tool로 수정한다.
4. RETRY += 1

**RETRY < 3** → 1번(테스트 실행)으로 돌아간다.

**RETRY ≥ 3** → 아래 실패 리포트를 출력하고 루프를 종료한다.

```
[Auto-Fix 실패]
- 시도 횟수: 3/3
- 마지막 에러: {에러 요약 2-3줄}
- 수정 시도한 파일: {목록}
→ 수동 개입이 필요합니다.
```
