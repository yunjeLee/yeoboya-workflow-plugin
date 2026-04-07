---
name: auto-fix
description: "테스트를 실행하고 실패 시 AI가 자동으로 수정·재시도한다. 최대 3회 시도. /auto-fix로 실행하며 플랫폼(Android/iOS)을 자동 감지한다."
---

# Auto-Fix Skill — 자동 교정 루프

테스트를 실행하고 실패 시 AI가 자동으로 원인을 분석해 수정한 뒤 재시도한다.

## 트리거
- `/auto-fix` — 플랫폼 자동 감지 후 루프 실행

---

## Step 1: 플랫폼 감지 및 테스트 명령어 결정

프로젝트 루트에서 아래 파일을 스캔해 테스트 명령어를 결정한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
  TEST_CMD=./gradlew test

*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
  TEST_CMD=xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'
  (SchemeName: .xcodeproj 내 scheme 목록 또는 xcodebuild -list 로 확인)

둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문 후 결정
```

---

## Step 2: 루프 초기화

루프 실행 전 아래를 초기화한다.

```
RETRY = 0 (최대 3회 시도)
MODIFIED_FILES = [] (수정한 파일 목록 누적)
```

---

## Step 3: 자동 교정 루프 (최대 3회 반복)

### 3-1. 테스트 실행

Bash tool로 `TEST_CMD`를 실행한다.

**테스트 성공 시 (exit code = 0):**

아래 리포트를 출력하고 루프를 종료한다.

```
[Auto-Fix 완료]
- 시도 횟수: {RETRY+1}/3
- 수정한 파일: {MODIFIED_FILES 목록. 없으면 "없음"}
- 테스트 결과: PASS
```

**테스트 실패 시 (exit code ≠ 0):**

stdout + stderr 전체를 캡처해 다음 단계로 이동한다.

### 3-2. 에러 분석 및 수정 (실패 시)

캡처한 에러 메시지를 분석한다.

1. **에러가 발생한 파일과 라인을 특정한다.**
   - 스택 트레이스 또는 에러 메시지에서 파일 경로 및 라인 번호 추출
   
2. **원인을 판단한다.**
   - 타입 오류, 로직 오류, 상태 관리 오류 등 근본 원인 파악
   
3. **파일을 수정한다.**
   - Read tool로 해당 파일을 읽고
   - Edit tool로 수정 사항을 적용
   - MODIFIED_FILES에 파일 경로 추가
   
4. **RETRY 증가**
   - `RETRY += 1`

### 3-3. 조건별 다음 단계

**에러 원인 분석 불가 (복합 버그, 설정 오류 등):**

마지막 에러와 함께 사용자에게 상황을 설명하고 지시를 요청한 후 그에 따른다.

**RETRY < 3:**

Step 3-1(테스트 실행)으로 돌아간다.

**RETRY ≥ 3:**

아래 실패 리포트를 출력하고 루프를 종료한다.

```
[Auto-Fix 실패]
- 시도 횟수: 3/3
- 마지막 에러: {에러 요약 2-3줄}
- 수정 시도한 파일: {MODIFIED_FILES 목록}
→ 수동 개입이 필요합니다.
```

---

## 핵심 규칙

- **RETRY 초기값:** 루프 시작 시 RETRY=0 으로 초기화
- **테스트 판정:** 일부만 pass 하는 경우(부분 성공)도 "실패"로 취급하고, 모든 테스트가 통과할 때까지 루프 계속
- **누적 수정:** 각 시도의 수정은 이전 수정사항을 반영해 누적 적용 (이전 시도에서 수정한 코드 위에 새로운 수정을 진행)
- **수정 파일 누적:** Edit tool 호출마다 수정 파일을 MODIFIED_FILES에 누적하고, 최종 리포트에 모두 나열한다.

---

## 완료 리포트 형식

### 성공 시
```
[Auto-Fix 완료]
- 시도 횟수: {N}/3
- 수정한 파일: {파일 목록 또는 "없음"}
- 테스트 결과: PASS
```

### 실패 시
```
[Auto-Fix 실패]
- 시도 횟수: 3/3
- 마지막 에러: {에러 요약 2-3줄}
- 수정 시도한 파일: {목록}
→ 수동 개입이 필요합니다.
```
