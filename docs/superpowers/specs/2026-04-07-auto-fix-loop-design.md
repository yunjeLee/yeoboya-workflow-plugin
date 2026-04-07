# Auto-Fix Loop — 설계 스펙

작성일: 2026-04-07

---

## 개요

CI 실패 시 AI가 에러를 분석해 자동으로 수정하고 재시도하는 루프 메커니즘.
사람이 개입하지 않아도 스스로 수정하고 반복한다.

```
테스트 실패 → 에러 캡처 → AI 분석 및 수정 → 재시도 (최대 3회)
```

---

## 변경 범위

| 파일 | 변경 유형 |
|------|----------|
| `shared/auto-fix-loop.md` | 신규 생성 — 핵심 루프 로직 |
| `skills/auto-fix/SKILL.md` | 신규 생성 — 단독 실행용 스킬 |
| `skills/phase/SKILL.md` | 수정 — Task 완료 후 루프 호출 추가 |
| `.claude-plugin/plugin.json` | 수정 — `/auto-fix` 스킬 등록 |

---

## 아키텍처

```
shared/auto-fix-loop.md       ← 핵심 루프 로직 (플랫폼 감지, 실행, 재시도)
skills/auto-fix/SKILL.md      ← 단독 실행용 스킬 (/auto-fix)
skills/phase/SKILL.md         ← Task 완료 후 auto-fix-loop 호출 추가
.claude-plugin/plugin.json    ← /auto-fix 스킬 등록
```

`shared/auto-fix-loop.md`는 기존 `shared/prompt-refiner.md` 패턴과 동일하게,
여러 스킬에서 `Read` tool로 읽어 따른다.
나중에 `/bugfix` 검증 단계에도 재사용 가능하다.

---

## shared/auto-fix-loop.md — 루프 메커니즘

### 플랫폼 감지

```
build.gradle 또는 build.gradle.kts 존재 → PLATFORM=Android
  명령어: ./gradlew test

*.xcodeproj 또는 *.xcworkspace 존재    → PLATFORM=iOS
  명령어: xcodebuild test -scheme <SchemeName> -destination 'platform=iOS Simulator,name=iPhone 15'

둘 다 없음 → "Android / iOS 중 어떤 프로젝트인가요?" 질문
```

### 루프 흐름

```
[루프 시작]
  ↓
플랫폼에 맞는 테스트 명령어 실행
  ↓ 성공 → [완료 리포트 출력 후 종료]
  ↓ 실패
에러 메시지 캡처 (stdout + stderr)
  ↓
AI가 에러 분석 → 원인 파일/라인 특정 → 수정 적용
  ↓
재시도 카운터 +1
  ↓
카운터 ≤ 3 → [테스트 실행으로 돌아감]
카운터 > 3 → [실패 리포트 출력 후 종료]
```

### 완료 리포트 형식

**성공 시:**
```
[Auto-Fix 완료]
- 시도 횟수: N/3
- 수정한 파일: [목록]
- 테스트 결과: PASS
```

**실패 시 (3회 초과):**
```
[Auto-Fix 실패]
- 시도 횟수: 3/3
- 마지막 에러: [에러 요약]
- 수정 시도한 파일: [목록]
→ 수동 개입이 필요합니다.
```

---

## skills/auto-fix/SKILL.md — 단독 실행 스킬

- 트리거: `/auto-fix`
- 동작: `shared/auto-fix-loop.md`를 Read tool로 읽고 루프 실행
- 플랫폼 자동 감지 (인자 없음)

---

## skills/phase/SKILL.md — Task별 루프 통합

### 변경 전 Step 3

```
superpowers:executing-plans 호출 → 전체 Phase 실행
```

### 변경 후 Step 3

```
Phase 내 각 Task 실행
  ↓ Task 완료
shared/auto-fix-loop.md 읽고 루프 실행
  ↓ 성공 → 다음 Task
  ↓ 3회 실패 → 사용자에게 보고
    "Task [이름] 자동 수정 실패. 계속할까요? (y/n)"
    - y → 다음 Task로 진행 (실패 기록)
    - n → Phase 중단, plan.md 업데이트 안 함
```

### Phase 완료 리포트 추가 항목

```
## Phase N 완료 리포트
- 성공한 Task: N개
- Auto-Fix 성공: N개
- 수동 처리 필요: N개
```

---

## 결정 사항

| 항목 | 결정 |
|------|------|
| 최대 재시도 횟수 | 3회 고정 |
| 명령어 지정 방식 | 플랫폼 자동 감지 |
| 루프 트리거 시점 (phase) | Task 하나 완료마다 |
| 루프 실패 시 동작 (phase) | 사용자에게 계속 여부 확인 |
| 공유 방식 | shared 모듈 (Read tool 참조) |
