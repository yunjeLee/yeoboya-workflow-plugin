# Verify-Module-Docs — 모듈 단위 하네스 검증 모듈

호출자 (`/harness-module`, `/harness-module-edit`) 가 Read tool 로 읽고 지침을 따른다. 4 축 검증 (consistency / referential integrity / reality-check / 50 줄 한도) 으로 모듈 CLAUDE.md 와 루트 하네스 사이의 결함을 잡는다.

`shared/verify-docs.md` 와 검증 대상 / 일부 축이 다르지만 사용자 인터페이스 (1/2/3 선택, [y/N/skip], 자동 수정 + 재점검) 는 동일하다.

## 진입 인터페이스

호출자는 다음 두 변수를 들고 진입한다.

- `target_modules`: 이번 실행에서 검증할 모듈 배열. 각 항목은 `{ name, path }` (module-detect.md 의 결과 일부).
- `mode`: `"create"` (harness-module 의 Step 7 직후) 또는 `"edit"` (harness-module-edit 의 마지막 Step).

호출 전 다음 파일이 모두 존재한다고 가정한다 (호출자 책임으로 이미 확인됨).

- 각 `{path}/CLAUDE.md`
- `docs/MODULE_MAP.md`
- 루트 `CLAUDE.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/ADR.md`, `docs/CONVENTIONS.md`, `docs/TESTING.md` (UI_GUIDE.md 는 존재 시만)

검증은 mode 에 따라 살짝 다르다.

| mode | 대상 | cross-file 비교 깊이 |
|---|---|---|
| `create` | `target_modules` 의 모든 모듈 + `docs/MODULE_MAP.md` | 루트 하네스 6 종 전체와 비교 |
| `edit` | `target_modules` 의 모듈 1 개 (수정된 섹션 우선) | 루트 하네스 + `docs/MODULE_MAP.md` 동일 비교 |

---

## 4 축 체크

### 축 1. consistency — 모듈 CLAUDE.md ↔ 루트 하네스 충돌

**대상 매트릭스**:

| 모듈 섹션 | 루트 비교 대상 | 충돌 예시 |
|---|---|---|
| 역할 (Q1) | `docs/PRD.md` 핵심 가치 / 출시 단계 | 모듈 역할이 PRD 의 어느 가치에도 닿지 않음 (orphan 모듈) |
| 절대 하면 안 되는 것 (Q3) | 루트 `CLAUDE.md` `CRITICAL` / `docs/CONVENTIONS.md` Claude 작업 스코프 | 모듈 Q3 가 CRITICAL 정면 위반 / CONVENTIONS 와 모순 |
| 의존성 (Q4) / 진입 파일 | `docs/ARCHITECTURE.md` 패턴 (Clean / 모듈 구조) | Clean Architecture 에서 domain → data 역방향 의존 |
| 모듈 코드 사용 라이브러리 추론 | `docs/ADR.md` 결정 | ADR 이 Hilt 결정인데 모듈에서 Koin 사용 |
| UI 모듈의 디자인 토큰 | `docs/UI_GUIDE.md` 컴포넌트 정책 | UI_GUIDE 의 토큰 무시한 하드코딩 |
| 모듈 테스트 진입 파일 | `docs/TESTING.md` 정책 | TESTING 의 테스트 레벨/도구 결정과 어긋남 |

**검사 방법**:

각 모듈에 대해:
1. `{path}/CLAUDE.md` Read.
2. 위 표의 매핑마다 핵심 키워드 추출 후 루트 문서와 비교.
3. 라이브러리 추론은 `{path}/build.gradle.kts` (Android) 또는 `{path}/Package.swift` 의 dependencies (iOS) 를 Read 해서 ADR 과 대조.

**심각도 분류**:

| 충돌 종류 | 심각도 |
|---|---|
| 루트 CLAUDE.md `CRITICAL` 정면 위반 | **CRITICAL** |
| `docs/ADR.md` / `docs/CONVENTIONS.md` 결정 충돌 | **WARNING** |
| 부가 어긋남 (디자인 토큰 명시 부재 등) | **INFO** |

**권장 수정 포맷**:

```
충돌: :feature:home/CLAUDE.md `의존성` ↔ docs/ARCHITECTURE.md `패턴`
  모듈: 의존하는 모듈 = `:data:repository`
  ARCHITECTURE: feature 는 domain 만 의존, data 직접 참조 금지
권장: 모듈 코드 정리 후 의존성 재추출 또는 ARCHITECTURE 의 Clean 주장 재검토.
```

---

### 축 2. referential integrity — 참조 / 그래프 무결성

**검사 항목**:

1. **진입 파일 경로 실제 존재**: 모듈 CLAUDE.md 의 `## 역할` 섹션에서 추론된 진입 파일 경로 (또는 본문에 명시된 경로) 가 Glob 으로 존재하는지.
2. **의존 모듈 매칭**: `## 의존성` 의 "의존하는 모듈" 목록이 `settings.gradle.kts` (Android) 또는 `Package.swift` (iOS) 에 선언돼 있는지.
3. **MODULE_MAP.md 행 ↔ 실제 모듈 디렉토리 CLAUDE.md 일치**:
   - 인덱스 행의 모듈명/경로가 실제 `{path}/CLAUDE.md` 와 일치하는지.
   - 인덱스에는 있는데 `{path}/CLAUDE.md` 가 없거나, 반대 케이스.
   - 인덱스의 "역할" 셀이 모듈 CLAUDE.md Q1 첫 문장과 동일한지 (drift 검출).

**심각도**:

| 결함 | 심각도 |
|---|---|
| 진입 파일 경로 부재 (모듈 본문 주장 ↔ 실제 fs 불일치) | **CRITICAL** |
| 의존 모듈이 settings.gradle.kts / Package.swift 에 없음 | **CRITICAL** |
| MODULE_MAP 행 ↔ 모듈 CLAUDE.md 부재 양방향 누락 | **CRITICAL** |
| MODULE_MAP "역할" 셀 ↔ 모듈 Q1 drift | WARNING |

**권장 수정 포맷**:

```
referential integrity CRITICAL — :feature:home/CLAUDE.md `의존성`
  모듈 주장: depends_on = [:core:network, :core:design]
  settings.gradle.kts: :core:design 은 include 되어 있지 않음
권장 A: 모듈 의존 선언 (build.gradle.kts) 을 다시 추출해 진실 소스 갱신.
권장 B: settings.gradle.kts 에 :core:design 을 추가 (의도한 모듈인 경우).
```

---

### 축 3. reality-check — 모듈 코드 ↔ 모듈 CLAUDE.md

**검사 항목**:

| 모듈 CLAUDE.md 주장 | 대조할 코드 스캔 |
|---|---|
| `## 역할 (Q1)` "이 모듈은 ~ 를 담당" | 모듈 진입 파일 (public class/interface, public func) 의 시그니처가 역할 주장과 부합하는지 |
| `## 절대 하면 안 되는 것 (Q3)` | 코드에 해당 안티 패턴이 실제로 있는지 (있으면 단순 경고가 아닌 실 위반) |
| `## 의존성 (Q4)` | 실제 build graph (`build.gradle.kts` / `Package.swift`) 와 일치 |

**검사 방법**:

1. 역할 주장: Glob 으로 `{path}/**/*.kt` 또는 `{path}/**/*.swift` Read 하여 public 시그니처 상위 5 개와 비교. 역할 키워드가 시그니처에 전혀 안 나타나면 의심.
2. Q3 위반: Q3 본문에서 추출한 금기 키워드를 모듈 코드 Grep. 매칭 시 **실제 위반** 으로 보고.
3. Q4 그래프: `module-detect.md` 의 `## 모듈 메타정보 수집` 절차를 모듈 1 개에 한정해 재실행하고, 결과를 모듈 CLAUDE.md 의 의존성 섹션과 비교.

**심각도**:

| 결과 | 심각도 |
|---|---|
| 역할 주장 ↔ public API 정반대 | **CRITICAL** |
| Q3 의 금기 패턴이 모듈 코드에 실제 존재 | **CRITICAL** |
| Q4 그래프 drift (의존 모듈 추가/삭제 미반영) | WARNING |
| 미약하게만 부합 (역할 주장의 키워드 1 개만 시그니처에 존재) | INFO |

**권장 수정 포맷**:

```
reality-check CRITICAL — :feature:home/CLAUDE.md `절대 하면 안 되는 것 (Q3)`
  주장: "Composable 안에서 Repository 직접 호출 금지"
  실제: HomeScreen.kt:42 에서 homeRepository.fetchUser() 직접 호출
권장 A: 코드를 ViewModel 경유로 리팩토링.
권장 B: Q3 항목을 현실에 맞게 완화 (단, ARCHITECTURE 와 충돌 여부 재확인 필요).
```

---

### 축 4. 50 줄 한도 검사

**검사 방법**:

각 모듈 CLAUDE.md 에 대해 `wc -l {path}/CLAUDE.md` 로 줄 수 측정.

**심각도**:

| 결과 | 심각도 |
|---|---|
| 51 줄 이상 | WARNING |

**권장 수정**:

`shared/module-claude-template.md` 의 `## 50 줄 한도 압축 규칙` 절차를 적용. 사용자 [Y/n] 으로 압축본 저장 여부 확인.

---

## 출력 포맷

모든 축 검사를 끝낸 뒤 한 번에 출력한다.

```
## Verify-Module-Docs 결과

### [{SEVERITY}] {축 이름} — {모듈 또는 파일}:{섹션}
  {발견 내용 요약 (1~2 줄)}
  권장: {구체 수정 제안}

### [{SEVERITY}] {축 이름} — {모듈 또는 파일}:{섹션}
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
## Verify-Module-Docs 결과

검출된 이슈 없음 (4 축 모두 통과)

완료 리포트로 진행합니다.
```

---

## 사용자 선택 처리

`shared/verify-docs.md` 의 "사용자 선택 처리" 와 동일 정책을 따른다. 요약:

### 1) 자동 수정

- CRITICAL + WARNING 만 대상으로 Edit 일괄 반영.
- 권장이 A/B 두 갈래로 갈리는 항목 (reality-check 의 코드 수정 vs 문서 수정 등) 은 자동 수정에서 제외하고 항목별 질문으로 승격.
- 50 줄 한도 검사의 압축은 `module-claude-template.md` 의 압축 규칙을 호출하고 사용자 [Y/n] 을 그대로 받는다 (자동 모드에서도 사용자 확인 1 회 필요).
- 수정 후 4 축 재점검 1 회. 재점검 2 회까지만 수행, 3 회째부터는 강제 종료하고 남은 이슈를 리포트에 기록.

### 2) 항목별 선택

이슈마다:

```
[{SEVERITY}] {축} — {모듈}:{섹션}
  {내용}
  권장: {수정안}

적용할까요? [y/N/skip]
```

- `y` → Edit 반영. 권장이 A/B 두 갈래면 추가로 "권장 A / B / 직접 입력 / skip" 묻기.
- `N` 또는 `skip` → 다음 이슈로.
- 전체 완료 후 수정된 이슈가 있으면 4 축 재점검 1 회 (자동 수정과 동일 규칙).

### 3) 그대로 진행

수정 없이 완료. 호출자 리포트 끝에 다음 블록 추가:

```
참고: Verify-Module-Docs 에서 {n} 건의 이슈가 남아있습니다.
      나중에 /harness-module-edit 또는 /harness-critique --module {경로} 로 재점검할 수 있습니다.
```

---

## 실행 완료 후

- 자동 수정 또는 항목별 선택의 결과로 **파일이 실제로 변경된 경우에만** 호출자(SKILL) 의 완료 리포트에 `(verify-module 반영)` 표기를 붙이도록 권한다.
- 재점검에서 이슈가 남아있으면 호출자 리포트에 남은 이슈 개수를 함께 표기.
