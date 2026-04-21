# Onboard — Self-Critique (Case 1/2 전용)

`/onboard` 의 Case 1 (전체 생성) 또는 Case 2 (일부 보완) 에서 문서 생성이 끝난 직후 이 절차를 실행한다. Case 3 (브리핑) 에서는 호출하지 않는다.

## 목적

방금 생성한 하네스 문서 세트(CLAUDE.md + docs/)의 **품질 결함을 완료 리포트 이전에 걸러낸다**. 완벽한 검증은 불가능하지만, 아래 5 축으로 실무상 80% 수준의 결함을 잡는 것을 목표로 한다.

## 실행 대상 파일

- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`
- `docs/UI_GUIDE.md` (존재 시)
- `docs/TESTING.md`
- `docs/CONVENTIONS.md`
- `docs/WORKFLOW.md`

Case 2 에서 **이번 onboard 실행으로 새로 생성한 파일만** 검증 대상으로 한다. 기존 파일은 건드리지 않는 원칙을 유지한다.

---

## 5 축 체크

### 축 1. ambiguity — 검증 불가능한 추상 표현

**대상 섹션**: CLAUDE.md 의 `CRITICAL 규칙`, `피해야 할 것`, `팀 컨벤션` / docs/ARCHITECTURE.md 의 `패턴`, `상태 관리` / docs/ADR.md 의 `이유`, `트레이드오프`.

**탐지 패턴**:
- 수식어 없는 추상 형용사: `적절한`, `좋은`, `효율적인`, `적합한`, `합리적인`, `현대적인`, `깔끔한`
- 평가 불가능한 부사: `잘`, `제대로`, `적당히`, `필요한 만큼`
- 프로젝트 고유성이 없는 보편 슬로건: `유지보수성이 좋은 코드`, `읽기 쉬운 코드 작성`, `효율적인 구조 추구`, `품질 높은 코드`

**제외 대상**:
- 이유 / 설명문 (예: "왜 이렇게 바꾸는지 설명한다" 같은 방법론 문장)
- PRD 의 `핵심 가치` 섹션 (프로덕트 가치관은 추상적이어도 OK)

**심각도**: WARNING (compliance check 가 기계적으로 작동할 수 없으면 하네스 가치가 떨어지므로)

**권장 수정 포맷**:
```
원본: "적절한 상태 관리"
권장: "ViewModel 은 StateFlow 로 상태 노출, mutableStateOf 사용 금지"
```

---

### 축 2. consistency — 파일 간 + 파일 내 규칙 충돌

**파일 간 검사 대상 조합**:
- CLAUDE.md `CRITICAL 규칙` ↔ ARCHITECTURE.md `패턴`
- CLAUDE.md `CRITICAL 규칙` ↔ ADR.md 결정
- CLAUDE.md `팀 컨벤션` ↔ ADR.md 결정
- ARCHITECTURE.md `패턴` ↔ ADR.md 결정

**파일 내 검사 대상**:
- CLAUDE.md 안의 `CRITICAL` / `피해야 할 것` / `응답 규칙` / `팀 컨벤션` 섹션 간
- 한 섹션 안의 문장들 간

**검사 방법**:
핵심 키워드 단위로 그룹화해서 규칙을 비교한다.

| 주제 키워드 | 비교 패턴 |
|-----------|----------|
| DI / injection / singleton | "Hilt 사용" vs "Koin 사용" 동시 존재, "constructor injection 우선" vs "field injection 통일" |
| state / StateFlow / mutableStateOf / LiveData | 상태 관리 방식이 파일마다 다르게 명시됨 |
| coroutine / Dispatcher / GlobalScope | scope 정책 충돌 |
| architecture / Clean / MVVM / MVI | 아키텍처 패턴 표기 불일치 |
| module / :domain / :data / :feature | 모듈 구조 주장과 규칙 불일치 |
| Compose / XML / UIKit / SwiftUI | UI 시스템 주장 충돌 |

**심각도**:
- CRITICAL 규칙끼리 모순 → CRITICAL
- CRITICAL vs ADR 불일치 → WARNING
- 부가 문장끼리 불일치 → INFO

**권장 수정 포맷**:
```
충돌 위치: CLAUDE.md CRITICAL 3 번 vs ADR-002
  CLAUDE.md: "모든 DI 는 Hilt constructor injection"
  ADR-002:   "DI = Koin"
권장: 둘 중 하나로 통일. 실제 레포의 build.gradle.kts 기준으로 재확인 필요.
```

---

### 축 3. completeness — [TBD] 과다 / 필수 섹션 누락

**검사 방법**:
각 파일을 Read 한 뒤 `[TBD]` 문자열 개수를 카운트하고, 필수 섹션의 내용이 비어있는지 확인한다.

**분류 기준**:

| 파일 / 섹션 | 상태 | 심각도 |
|-----------|------|-------|
| CLAUDE.md `CRITICAL 규칙` 전체가 [TBD] / 빈 리스트 | 하네스 핵심 부재 | **CRITICAL** |
| docs/ARCHITECTURE.md 전체가 [TBD] | 스캔 결과가 빈약 | **CRITICAL** |
| CLAUDE.md `팀 컨벤션` 전체가 [TBD] | 부가 정보 부재 | WARNING |
| docs/ADR.md 전 항목의 `이유` / `트레이드오프` 가 [TBD] | 결정 근거 부재 | WARNING |
| docs/PRD.md 의 개별 필드 [TBD] | 나중에 채우면 됨 | INFO |
| docs/UI_GUIDE.md `원칙` [TBD] | 스캔 성공했는데 비움 | WARNING |
| docs/TESTING.md 전체 [TBD] | 테스트 방침 미정 | INFO |
| docs/TESTING.md `테스트 레벨` + `CI 연동` 모두 [TBD] | 테스트 실행 방식 불명 | WARNING |
| docs/CONVENTIONS.md `Claude 작업 스코프` [TBD] | Claude 실수 방지 규칙 부재 | **WARNING** |
| docs/CONVENTIONS.md 기타 필드 [TBD] | 나중에 채우면 됨 | INFO |

**권장 수정 포맷**:
```
docs/ARCHITECTURE.md 디렉토리 구조 / 패턴 / 데이터 흐름 / 상태 관리 모두 [TBD]
원인 추정: 자동 스캔이 실패했거나 모듈 인식이 안 됨
권장: settings.gradle.kts 경로 확인 또는 iOS 의 경우 Package.swift / xcodeproj 존재 확인 후 재생성
```

---

### 축 4. referential integrity — `@참조` 파일 실제 존재 여부

**검사 방법**:
1. CLAUDE.md 를 Read 하고 `@docs/*.md` 패턴을 추출한다.
2. 각 참조 경로에 대해 Glob 으로 실제 존재 여부 확인.

**심각도**:
- 참조 파일 부재 → **CRITICAL** (Claude Code 가 `@` 참조를 해석할 때 경고 또는 무시됨, 하네스 가드레일이 끊김)
- `docs/UI_GUIDE.md` 는 예외 — onboard-create.md 규칙상 디자인 시스템 미감지 시 참조만 유지하는 설계. 해당 파일 부재는 **INFO** 로 낮춘다.

**권장 수정 포맷**:
```
CLAUDE.md L8: @docs/FOO.md 참조
실제: 파일 없음
권장: 참조 제거 또는 해당 파일 생성
```

---

### 축 5. reality-check — 레포 실제 상태와 문서 주장 대조

**검사 방법**:
`shared/onboard-create.md` 의 자동 스캔 절차를 **다시 실행**하고, 그 결과를 생성된 문서의 주장과 교차 비교한다.

**Android 검사 항목**:

| 문서 주장 (ARCHITECTURE.md / ADR.md / CLAUDE.md CRITICAL) | 대조할 레포 스캔 |
|----------------------------------------------------|---------------|
| "Clean Architecture" | `settings.gradle.kts` 에 `:domain`, `:data`, `:feature` 계열 모듈 존재 여부 |
| "Jetpack Compose" | `libs.versions.toml` 또는 `build.gradle.kts` 에 `androidx.compose.*` 의존성 존재 여부 |
| "StateFlow 기반 상태 관리" | `kotlinx.coroutines.flow` 사용 여부 (Grep `StateFlow`, `flow {` 등) |
| "Hilt DI" | `hilt-android` 또는 `dagger.hilt.*` 의존성 존재 여부 |
| "Retrofit / Ktor / Alamofire" 등 라이브러리 결정 | 실제 build.gradle.kts 또는 Podfile 에 해당 라이브러리 존재 여부 |
| "MVI 패턴" | `Intent`, `reduce`, `SideEffect` 키워드의 코드 내 실제 사용 여부 |
| "단일 모듈" | `settings.gradle.kts` 의 `include` 개수가 1 개인지 |
| "멀티 모듈" | `include` 개수가 2 개 이상인지 |

**iOS 검사 항목**:

| 문서 주장 | 대조할 레포 스캔 |
|---------|---------------|
| "SwiftUI" | `Package.swift` 또는 프로젝트 파일에 SwiftUI import, `@main App` 구조 존재 여부 |
| "UIKit" | `UIViewController`, `UIApplicationDelegate` 사용 여부 |
| "Combine 상태 관리" | `@Published`, `PassthroughSubject` 등의 실제 사용 여부 |
| "Clean Architecture" | `Sources/Domain/`, `Sources/Data/`, `Sources/Features/` 디렉토리 존재 여부 |
| 라이브러리 결정 (Alamofire / Kingfisher 등) | Podfile / Cartfile / Package.swift 에 실제 선언 여부 |

**심각도 분류**:
- 문서 주장과 레포 실상이 **정반대** (예: "Clean Architecture" 주장하지만 단일 모듈) → **CRITICAL**
- 문서 주장의 라이브러리가 레포에 **아예 없음** (예: "Hilt" 주장하지만 Koin 만 있음) → **CRITICAL**
- 문서 주장의 패턴이 레포에 **미약하게만** 있음 (예: "MVI" 주장하지만 Intent 파일 1~2 개뿐) → WARNING
- 레포에 있지만 문서에 누락 (예: 레포엔 Retrofit 있는데 ADR 에 네트워크 항목 [TBD]) → INFO

**권장 수정 포맷**:
```
reality-check CRITICAL — docs/ARCHITECTURE.md `패턴`
  문서 주장: "Clean Architecture (domain/data/feature 계층)"
  레포 실제: :app 단일 모듈만 존재 (settings.gradle.kts 기준)
  권장 A: ARCHITECTURE.md 를 "단일 모듈 MVVM" 으로 수정
  권장 B: Clean 이관이 예정이라면 ADR 에 "현재는 단일 모듈, Clean 이관 예정" 으로 명시
```

---

## 출력 포맷

모든 축 검사를 끝낸 뒤 아래 포맷으로 한 번에 출력한다.

```
## Self-Critique 결과

### [{SEVERITY}] {축 이름} — {파일}:{섹션 또는 라인}
  {발견 내용 요약 (1~2 줄)}
  권장: {구체 수정 제안}

### [{SEVERITY}] {축 이름} — {파일}:{섹션 또는 라인}
  ...

---
총 {N} 건 (CRITICAL {n}, WARNING {n}, INFO {n})

어떻게 할까요?
  1) 자동 수정 (CRITICAL + WARNING 만) — 제안대로 Edit 반영 후 재점검
  2) 항목별 선택 — 각 이슈마다 y / N / skip 질문
  3) 그대로 진행 — 수정 없이 완료 리포트로

번호 선택:
```

**심각도 없음 (0 건)** 인 경우:
```
## Self-Critique 결과

검출된 이슈 없음 (5 축 모두 통과)

완료 리포트로 진행합니다.
```

---

## 사용자 선택 후 처리

### 1) 자동 수정

- CRITICAL + WARNING 항목만 대상으로 Edit tool 로 권장 수정을 일괄 반영
- reality-check 의 경우 "권장 A / B" 같이 선택지가 여러 개면 **자동 수정에서 제외**하고 항목별 질문으로 승격
- 수정 후 5 축 재점검 1 회 실행
- 새 이슈 발견 시 다시 출력 (재점검 2 회까지만, 3 회째부터는 "완료 리포트로 진행" 으로 강제 종료하고 남은 이슈를 리포트에 기록)
- 이슈 없음 → 완료 리포트

### 2) 항목별 선택

이슈마다 순차 질문:
```
[{SEVERITY}] {축} — {파일}
  {내용}
  권장: {수정안}

적용할까요? [y/N/skip]
```

- `y` → Edit 로 수정
- `N` 또는 `skip` → 다음 이슈로
- 전체 완료 후 수정된 이슈가 있으면 재점검 1 회 (자동 수정과 동일 규칙)

### 3) 그대로 진행

수정 없이 완료 리포트로 이동. 단, 완료 리포트 끝에 다음 블록을 추가한다:

```
참고: Self-Critique 에서 {n} 건의 이슈가 남아있습니다.
      나중에 `/onboard` 의 Case 2 (보완 모드) 또는 `/review` 로 재점검할 수 있습니다.
```

---

## 실행 완료 후

- 자동 수정 또는 항목별 선택의 결과로 **파일이 실제로 변경된 경우에만** 완료 리포트의 "생성 파일" 목록 옆에 `(critique 반영)` 표기를 붙인다.
- 재점검에서 이슈가 남아있으면 완료 리포트에 남은 이슈 개수를 함께 표기한다.
