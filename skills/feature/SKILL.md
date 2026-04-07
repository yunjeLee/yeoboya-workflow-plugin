---
name: feature
description: "기획서(PDF) 또는 텍스트 설명을 기반으로 기능 개발 또는 유지보수 작업을 수행한다. /feature, 기능 개발, 기획서 구현, 기능 추가, '이런 기능 만들어줘', spec 기반 개발 요청 시 반드시 사용한다. PDF 첨부 없이 말로 설명해도 동일하게 동작한다."
---

# Feature Skill — 기능 개발 / 유지보수

기획서(PDF) 또는 텍스트 설명을 기반으로 기능 개발 또는 유지보수 작업을 수행한다.

## 트리거
- `/feature 기획서.pdf` — PDF 기획서로 시작
- `/feature [기능 설명]` — 텍스트로 직접 설명
- `/feature 기획서.pdf --prev 이전기획서.pdf` — 기획서 수정 대응

---

## 공통 지침 참조
- 시작 시: `shared/prompt-refiner.md`를 Read tool로 읽고 지침을 따른다.
- UI 작업 감지 시: `shared/ui-review.md`를 Read tool로 읽고 지침을 따른다.

---

## Step 1: 플랫폼 자동 감지

프로젝트 루트에서 아래 파일을 스캔한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문
```

감지된 플랫폼을 이후 모든 단계에서 사용한다.

---

## Step 2: 기획서 분석 및 경로 분기

Claude가 직접 두 PDF를 분석해 변경 사항을 추출한다.
완료된 작업 목록은 `.yeoboya-state.json`의 `completedTasks` 필드를 참조한다.

**신규 기획서인 경우** (`--prev` 없음):
→ Step 3으로 이동

**기획서 수정인 경우** (`--prev` 있음):
1. 두 PDF를 비교해 변경 / 추가 / 삭제 항목을 추출한다.
2. 이미 완료된 작업 목록과 대조해 영향받는 항목만 식별한다.
3. 변경 영향 요약을 출력한다.
   ```
   [변경 감지]
   - 추가된 요구사항: ...
   - 수정된 요구사항: ...
   - 삭제된 요구사항: ...
   - 영향받는 완료 작업: ...
   ```
4. 변경분만 대상으로 Step 3(brainstorming)부터 다시 진행한다. 단, 변경이 없는 완료 작업은 건너뛴다.

---

## Step 3: 요구사항 명확화 (brainstorming)

`superpowers:brainstorming` 스킬을 호출한다.
- PDF 내용을 기반으로 모호한 요구사항을 질문한다.
- 확정된 요구사항 목록을 작성한다.

---

## Step 4: 구현 계획 작성 (writing-plans)

`superpowers:writing-plans` 스킬을 호출한다.
- 확정된 요구사항을 기반으로 단계별 구현 계획을 작성한다.

---

## Step 5: 구현 실행 (executing-plans + Worker 격리)

`superpowers:executing-plans` 스킬을 호출한다.

각 작업 단위마다 아래 순서를 따른다.
1. `agents/writer.md` 기반 구현 subagent 실행 → 코드 작성 + 테스트
   - 테스트 실행은 구현 subagent(writer.md)가 담당한다.
2. 테스트 실패 시: 에러 메시지를 구현 subagent에 피드백 → 수정 → 재실행
3. 테스트 통과 후: `agents/reviewer.md` 기반 검토 subagent 실행
4. CHANGES REQUESTED 시: 수정 사항을 구현 subagent에 전달 → 수정 → 재검토

Writer/Reviewer 루프 종료 조건:
- 루프 최대 3회까지 반복한다.
- 3회 초과 시 실패 사항을 사용자에게 보고하고 진행 여부를 확인한다.

플랫폼별 테스트 명령어:
- Android: `./gradlew test`
- iOS: `xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'`

---

## Step 6: 완료 검증 (verification-before-completion)

`superpowers:verification-before-completion` 스킬을 호출한다.
- 모든 요구사항이 구현됐는지 체크리스트로 확인한다.
- 통과 후 완료 리포트를 출력한다.

---

## 완료 리포트 형식

```
## Feature 완료 리포트
- 플랫폼: Android / iOS
- 기획서: [파일명]
- 변경 모드: 신규 / 수정 대응
- 구현 항목:
  - [x] 요구사항 A
  - [x] 요구사항 B
- 테스트 결과: PASS
- 검토 결과: APPROVED
```
