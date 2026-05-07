---
name: harness-module-refresh
description: "이미 생성된 모듈 CLAUDE.md ({path}/CLAUDE.md) 를 모듈 코드와 비교해 drift 를 감지하고 갱신안을 제안한다. /harness-module-refresh {모듈} 형태로 모듈 경로를 인자로 받는다. 인자 누락 시 모듈 목록을 표시한다. decay 알림, 모듈 코드 변화 점검, 모듈 CLAUDE.md 최신화 요청 시 사용한다."
model: opus
---

# Harness-Module-Refresh Skill — 모듈 코드 ↔ CLAUDE.md drift 점검

`{path}/CLAUDE.md` 를 같은 모듈의 실제 코드와 비교해서 drift 를 잡는다. 자동 점검 대상은 **Q1 (역할/진입 파일) / Q3 (절대 하면 안 되는 것) / Q4 (의존성)** 3 섹션. Q2/Q5 는 코드만으로 추론 어려우므로 본 스킬에서 다루지 않는다 (필요 시 `/harness-module-edit` 안내).

## 트리거

- `/harness-module-refresh {모듈}` — Gradle path (`:feature:home`) / iOS target 명 (`Home`) / 디렉토리 경로
- `/harness-module-refresh` — 점검 가능한 모듈 목록 표시
- decay hook 알림에서 안내된 경우

---

## Step 1: 모듈 감지 + 인자 처리

1. `shared/module-detect.md` 를 Read tool 로 읽고 `modules` 배열 확보.
2. `{path}/CLAUDE.md` 가 존재하는 모듈만 `refreshable_modules` 로 좁힘.
3. `refreshable_modules` 가 0 개면 종료:

   ```
   점검 가능한 모듈 CLAUDE.md 가 없습니다.
   먼저 /harness-module 을 실행하세요.
   ```

4. 인자 분기:
   - **누락** → `refreshable_modules` 표 출력 후 번호 또는 모듈명 입력 받기.
   - **있음** → `skills/harness-module/SKILL.md` Step 4 의 "인자 정규화 / 인자 검증" 로직 그대로 적용. 매칭 실패 시 목록 표시 후 종료.

매칭된 모듈을 `target_module` 로 확정.

---

## Step 2: 모듈 코드 / 빌드 정의 수집

1. 진입 파일 후보 (public 시그니처 기준 상위 우선):
   - Android: Glob `{path}/**/*.kt` 결과에서 본문에 `^(public\s+)?(interface|class|object|sealed)\b` 매칭이 있는 파일 → 상위 5 개.
   - iOS: Glob `{path}/**/*.swift` 결과에서 `^(public|open)\b` 매칭이 있는 파일 → 상위 5 개.
2. 빌드 정의:
   - Android: `{path}/build.gradle.kts` 또는 `{path}/build.gradle`.
   - iOS: 루트 `Package.swift` 또는 모듈의 `Project.swift`.
3. 위 파일 목록을 `code_files`, 빌드 정의를 `build_def` 로 보관.

`code_files` 가 0 개면 "{모듈} 의 코드 진입 파일을 찾지 못했습니다. 점검 종료." 출력 후 종료.

---

## Step 3: 모듈 CLAUDE.md Read

1. `{path}/CLAUDE.md` Read.
2. H2 단위로 5 섹션 (Q1 ~ Q5) 본문 추출. 본 스킬은 그중 Q1 / Q3 / Q4 만 사용.

---

## Step 4: 비교 (정형 규칙 + LLM 하이브리드)

각 섹션마다 **정형 규칙으로 후보 신호 선별 → LLM 이 drift 여부 최종 판정** 한다. drift 없으면 그 섹션은 갱신 후보에서 제외.

### Q1 (역할 / 진입 파일)

**정형 규칙 (후보 추출)**:

- `code_files` 의 public 시그니처 (Kotlin: `interface\|class\|object\|sealed` 라인, Swift: `public\|open` 함수/타입) 상위 5 개를 모은다 (`current_signatures`).
- 모듈 CLAUDE.md Q1 본문에서 명시된 진입 파일 경로 / 클래스명을 추출한다 (`claimed_signatures`).

**LLM 판정**:

- Q1 본문의 "역할" 주장 (모듈이 무엇을 담당한다고 주장하는지) 이 `current_signatures` 와 부합하는가?
- `claimed_signatures` 중 `code_files` 에 더 이상 존재하지 않는 것이 있는가? (삭제된 진입점)
- `current_signatures` 중 `claimed_signatures` 에 없는 새 public 진입점이 있는가? (추가된 진입점)

세 질문 중 하나라도 "어긋남" → Q1 을 갱신 후보로 표시 + 새 초안 생성 (template 의 Q1 자동 추론 절차 사용).

### Q3 (절대 하면 안 되는 것)

**정형 규칙 (후보 추출)**:

- Q3 본문에서 금기 키워드 추출 (예: "Composable 안에서 Repository 직접 호출", "Activity 직접 참조" 등).
- 각 키워드의 핵심 토큰 (`Repository`, `Activity` 등) 을 `code_files` Grep.

**LLM 판정**:

- Grep 매칭이 있다면, 실제 안티 패턴 사용 사례인지 (LLM 이 코드 컨텍스트 보고 판정).
- 진짜 위반 케이스가 있는데 Q3 가 그 위반을 다루지 않거나 (강도 부족), 반대로 Q3 가 다루는 안티 패턴이 모듈 코드에 전혀 안 나타나면 (오버스펙) → Q3 을 갱신 후보.

오버스펙 (Q3 항목이 모듈 코드와 무관) 만으로는 갱신 후보로 자동 등록하지 않는다 (false positive 위험). 실제 위반 발견 시에만 갱신 후보.

### Q4 (의존성)

**정형 규칙 (drift 판정 — LLM 불필요)**:

- `module-detect.md` 의 `depends_on` 추출 절차를 `target_module` 1 개에만 적용해 `current_depends_on` 산출.
- Q4 본문의 "의존하는 모듈" 목록 → `claimed_depends_on`.
- 두 집합 비교:
  - `current_depends_on - claimed_depends_on` (새로 추가된 의존)
  - `claimed_depends_on - current_depends_on` (제거된 의존)
- 어느 쪽이든 비어있지 않으면 Q4 를 갱신 후보 + 새 초안 생성 (template 의 Q4 자동 추론 절차).

### 분기

- 갱신 후보 ≥ 1 → Step 5 의 "변경 필요" 흐름.
- 갱신 후보 = 0 → Step 5 의 "변경 불필요" 흐름.

---

## Step 5: 결과 분기

### 변경 필요

후보 섹션마다 [기존] / [새 초안] 나란히 출력 후 [y/N]:

```
## 역할 (Q1)

[기존]
{현재 CLAUDE.md 의 해당 섹션}

[새 초안]
{비교 결과 + 자동 추론으로 생성한 초안}

이 섹션을 새 초안으로 갱신할까요? [y/N]
```

`y` → 적용 대상. 빈 입력 또는 `N` → skip.

순회 후 적용 대상 0 개면 Step 6 (수정 없이 리포트).

적용 대상 ≥ 1 개:

1. `{target_module.path}/CLAUDE.md` Edit 으로 H2 블록 단위 교체. **다른 섹션은 절대 수정하지 않음.**
2. `wc -l {path}/CLAUDE.md` 측정. 51 줄 이상이면 `shared/module-claude-template.md` 의 `## 50 줄 한도 압축 규칙` 적용.
3. **Verify-Module-Docs 자동 호출**:
   - `shared/verify-module-docs.md` Read.
   - `target_modules`: `[target_module]`, `mode`: `"edit"`.
   - 검증 모듈의 사용자 선택 처리 (1 / 2 / 3) 그대로 따름. cross-file 비교 시 루트 CLAUDE.md, MODULE_MAP, 루트 docs 도 참조.

### 변경 불필요

```
{모듈명} CLAUDE.md 는 현행 유지해도 됩니다.

자동 점검 결과 — drift 없음:
- 역할 (Q1): public 시그니처와 일치
- 절대 하면 안 되는 것 (Q3): 코드에서 위반 사례 미발견
- 의존성 (Q4): build 그래프와 일치

Q2 (표준 작업 흐름) / Q5 (명시되지 않은 규칙) 은 본 스킬 점검 대상 밖입니다.
필요 시 /harness-module-edit {모듈} 로 직접 수정하세요.
```

출력 후 종료 (Step 6 skip).

---

## Step 6: 완료 리포트

```
## /harness-module-refresh 완료 리포트
- 대상 모듈: {모듈명}
- 대상 파일: {path}/CLAUDE.md
- 점검 섹션: Q1 / Q3 / Q4
- 갱신 후보: {섹션 헤더 목록 / 또는 "없음"}
- 수정한 섹션: {실제 수정 헤더 목록 / 또는 "없음 — 사용자가 모두 skip"}
- 검증: {Verify-Module-Docs 결과 — 통과 / N 건 자동 수정 / N 건 남음 / skip}

다음 단계:
  IDE 에서 검토 후 직접 commit. (모듈 CLAUDE.md 는 Hook 차단 대상 아님)
```
