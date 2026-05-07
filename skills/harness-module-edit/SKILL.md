---
name: harness-module-edit
description: "이미 생성된 모듈 CLAUDE.md ({path}/CLAUDE.md) 를 git diff 기반으로 갱신한다. /harness-module-edit {모듈} 형태로 모듈 경로를 인자로 받는다. 인자 누락 시 모듈 목록을 표시한다. 모듈 하네스 수정, 모듈 CLAUDE.md 갱신, 코드 변경 반영 요청 시 사용한다."
model: opus
---

# Harness-Module-Edit Skill — 모듈 CLAUDE.md 부분 수정

이미 생성된 `{path}/CLAUDE.md` 를 git diff 기반으로 갱신한다. 다른 섹션은 절대 건드리지 않는다.

## 트리거
- `/harness-module-edit {모듈}` — Gradle path (`:feature:home`) / iOS target 명 (`Home`) / 디렉토리 경로
- `/harness-module-edit` — 편집 가능한 모듈 목록 표시

---

## Step 1: 모듈 감지 + 인자 처리

1. `shared/module-detect.md` 를 실행해 `modules` 배열 확보.
2. `{path}/CLAUDE.md` 가 존재하는 모듈만 `editable_modules` 로 좁힘.
3. `editable_modules` 가 0 개면 종료:

   ```
   편집 가능한 모듈 CLAUDE.md 가 없습니다.
   먼저 /harness-module 을 실행하세요.
   ```

4. 인자 분기:
   - **누락** → 표 출력 후 번호 또는 모듈명 입력 받기.
   - **있음** → `skills/harness-module/SKILL.md` 의 Step 4 "인자 정규화 / 인자 검증" 로직을 그대로 적용. 매칭 실패 시 `editable_modules` 목록 표시 후 종료.

매칭된 모듈을 `target_module` 로 확정.

---

## Step 2: git diff 추출

```bash
base=$(git log -1 --format='%H' -- {path}/CLAUDE.md)
git diff $base..HEAD -- {path}
```

| 케이스 | 처리 |
|---|---|
| `git log` 결과 비어있음 (한 번도 commit 안 됨) | `git diff HEAD -- {path}` 로 working tree 비교 |
| diff 결과 비어있음 | "{모듈명} 의 코드 변경사항이 없습니다" 출력 후 종료 |

기준 시점은 Step 6 리포트용으로 짧은 형태 (`%h (%ar)`) 보존.

---

## Step 3: 갱신 후보 자동 추천

| 변경 신호 | 매핑 섹션 |
|---|---|
| 진입 파일 / public API (`.kt`: `public interface\|class`, top-level `interface\|class`. `.swift`: `public func`, `open class`, `public struct\|protocol`) | **역할 (Q1)** |
| 선언 파일 의존성 (`build.gradle(.kts)` 의 `implementation\|api\|project(":...")` / `Package.swift` target dependencies) | **의존성 (Q4)** |

`import` 문 변경은 무시.

분기:
- 후보 ≥ 1 → Step 4 자동 추천 흐름.
- 후보 = 0 (변경은 있으나 미매칭) → Step 4 5 섹션 메뉴 흐름.

---

## Step 4: 새 초안 제안 + 섹션별 [y/N]

### 자동 추천 흐름

후보 섹션마다 반복:

1. `shared/module-claude-template.md` 의 해당 자동 추론 절차로 새 초안 생성.
   - 역할 (Q1) → `## 자동 추론 가이드 (Q1 / Q4)` 의 Q1 절차.
   - 의존성 (Q4) → 같은 가이드의 Q4 절차.
2. 기존 / 새 초안 나란히 출력 후 [y/N]:

   ```
   ## 역할 (Q1)

   [기존]
   {현재 CLAUDE.md 의 해당 섹션}

   [새 초안]
   {자동 추론 결과}

   이 섹션을 새 초안으로 갱신할까요? [y/N]
   ```

3. `y` → 적용 대상. 빈 입력 또는 `N` → skip.

순회 후 적용 대상이 0 개면 Step 6 (수정 없이 리포트).

### 5 섹션 메뉴 흐름

```
{모듈명} 의 자동 추천 후보가 없습니다.

수정할 섹션을 직접 선택하세요 (다중 선택 가능, 콤마 구분):
  1) 역할 (Q1)
  2) 표준 작업 흐름 (Q2)
  3) 절대 하면 안 되는 것 (Q3)
  4) 의존성 (Q4)
  5) 명시되지 않은 규칙 (Q5)

번호 입력 — 빈 입력 시 종료:
```

선택된 섹션 각각에 자동 추천 흐름의 초안 생성 + [기존]/[새 초안] + [y/N] 동일 적용.

---

## Step 5: 부분 수정 (Edit 도구)

`{target_module.path}/CLAUDE.md` Read → Edit 으로 H2 블록 단위 교체.

- **블록 단위**: 선택된 섹션의 `## ...` 헤더부터 다음 H2 헤더 (또는 파일 끝) 직전까지.
- **다른 섹션은 절대 수정하지 않음.**

수정 후 `wc -l {path}/CLAUDE.md` 측정. 51 줄 이상이면 `shared/module-claude-template.md` 의 `## 50 줄 한도 압축 규칙` 적용.

---

## Step 5.5: Verify-Module-Docs 자동 호출

Step 5 에서 1 개 이상 섹션이 실제로 수정된 경우에만 실행한다 (모두 skip 된 경우 본 단계도 skip).

1. `shared/verify-module-docs.md` 를 Read tool 로 읽는다.
2. 다음 변수로 호출한다.
   - `target_modules`: `[target_module]` (단일 모듈).
   - `mode`: `"edit"`.
3. 검증 모듈의 출력 포맷 / 사용자 선택 처리 (1 / 2 / 3) 를 그대로 따른다. cross-file 비교 시 루트 CLAUDE.md, MODULE_MAP, 루트 docs 도 참조한다.
4. 결과 (수정 반영 여부, 남은 이슈 수) 를 Step 6 완료 리포트에 반영한다.

---

## Step 6: 완료 리포트

```
## /harness-module-edit 완료 리포트
- 대상 모듈: {모듈명}
- 대상 파일: {path}/CLAUDE.md
- diff 기준: {짧은 hash + 상대 시간 / 또는 "첫 작성 (working tree)"}
- 수정한 섹션: {섹션 헤더 목록 / 또는 "없음 — 사용자가 모두 skip"}
- 검증: {Verify-Module-Docs 결과 — 통과 / N 건 자동 수정 / N 건 남음 / skip}

다음 단계:
  IDE 에서 검토 후 직접 commit. (모듈 CLAUDE.md 는 Hook 차단 대상 아님)
```
