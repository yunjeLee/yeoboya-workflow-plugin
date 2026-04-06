---
name: migration
description: "기획서(PDF) 또는 텍스트 설명을 기반으로 코드 마이그레이션을 수행한다. /migration, 라이브러리 전환, 아키텍처 변경, 코드 이전, 마이그레이션 요청 시 반드시 사용한다. PDF 없이 마이그레이션 목표를 말로 설명해도 동일하게 동작한다."
---

# Migration Skill — 마이그레이션

기획서(PDF) 또는 텍스트 설명을 기반으로 마이그레이션을 수행한다.

## 트리거
- `/migration 기획서.pdf` — PDF 기획서로 시작
- `/migration [마이그레이션 목표 설명]` — 텍스트로 직접 설명

---

## 공통 지침 참조
- 시작 시: `shared/prompt-refiner.md` 지침을 따른다.
- UI 작업 감지 시: `shared/ui-review.md` 지침을 따른다.

---

## Step 1: 플랫폼 자동 감지

프로젝트 루트에서 아래 파일을 스캔한다.

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문
```

---

## Step 2: 현재 코드베이스 분석

마이그레이션 대상 범위를 파악한다.
- 영향받는 파일 목록
- 의존성 관계
- 마이그레이션 위험도 (높음 / 보통 / 낮음)

분석 결과를 출력한 후 진행 여부를 확인한다.
- 사용자가 "예"를 선택하면 Step 3으로 진행한다.
- 사용자가 "아니오"를 선택하면 마이그레이션 범위 재조정 후 Step 2를 반복한다.

---

## Step 3: 마이그레이션 계획 작성 (writing-plans)

`superpowers:writing-plans` 스킬을 호출한다.
- 마이그레이션을 독립 가능한 단위로 분리한다.
- 각 단위가 완료 후 빌드 가능한 상태를 유지하도록 순서를 설계한다.

---

## Step 4: 병렬 실행 (subagent-driven-development)

`superpowers:subagent-driven-development` 스킬을 호출한다.
- 독립적인 마이그레이션 작업을 병렬로 처리한다.
- 각 작업 완료 후 `agents/writer.md` 기반 subagent가 구현한다.

플랫폼별 테스트 명령어:
- Android: `./gradlew test`
- iOS: `xcodebuild test -scheme <SchemeName: 프로젝트 스킴명으로 교체> -destination 'platform=iOS Simulator,name=iPhone 15'`

---

## Step 5: 무결성 검토

`agents/reviewer.md` 기반 검토 subagent를 실행한다.
- 마이그레이션 전후 동작이 동일한지 검토한다.
- 누락된 마이그레이션 항목이 없는지 확인한다.

---

## Step 6: 완료 검증 (verification-before-completion)

`superpowers:verification-before-completion` 스킬을 호출한다.

---

## 에러 처리

마이그레이션 중 특정 단계가 실패하면:
1. 현재까지 완료된 작업 목록을 `.yeoboya-state.json`에 저장한다.
2. 실패 원인과 영향 범위를 사용자에게 보고한다.
3. "중단 / 재시도 / 건너뜀" 중 진행 방식을 사용자에게 확인한다.

---

## 완료 리포트 형식

```
## Migration 완료 리포트
- 플랫폼: Android / iOS
- 마이그레이션 범위: [설명]
- 처리 단위 수: N개
- 테스트 결과: PASS
- 검토 결과: APPROVED
```
