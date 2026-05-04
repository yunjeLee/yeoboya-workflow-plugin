---
name: harness-map
description: "프로젝트의 모듈 단위 CLAUDE.md 와 docs/MODULE_MAP.md 인덱스를 생성한다. /harness-map, 모듈 맵 생성, 모듈별 CLAUDE.md, 모듈 단위 하네스 요청 시 반드시 사용한다. 하네스 핵심 6 종 부재 시 /harness 안내 후 종료."
model: opus
---

# Harness Map Skill — 모듈 단위 코드베이스 맵

루트 하네스가 이미 세팅된 프로젝트에서 모듈 단위 `CLAUDE.md` 를 생성하고, 전체 모듈을 한눈에 보는 `docs/MODULE_MAP.md` 인덱스를 만든다. 빌드 그래프 자동 추출 + 사용자 검토를 결합해 모듈 1 개씩 순차 처리하며, 중간 중단/재개를 progress 파일로 지원한다.

## 트리거
- `/harness-map` — 프로젝트 루트에서 실행

---

## Step 1: 플랫폼 자동 감지

`shared/workflow.md` 를 Read tool 로 읽고 **플랫폼 자동 감지** 섹션 지침을 그대로 따른다.

> 주의: **하네스 문서 부재 감지** 섹션은 이 스킬에서 건너뛴다 (순환 방지 — 부재 확인은 Step 2 에서 자체적으로 수행).

---

## Step 2: 하네스 부재 확인

Glob tool 로 핵심 6 종의 존재 여부를 확인한다.

- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`
- `docs/TESTING.md`
- `docs/CONVENTIONS.md`

하나라도 부재하면 아래 메시지를 출력하고 즉시 종료한다.

```
모듈 맵을 만들기 전에 하네스 문서가 먼저 있어야 합니다.

먼저 /harness 를 실행해 하네스 문서를 생성하세요.
누락된 파일:
  - {실제 누락 파일 경로}
```

6 종 모두 존재하면 Step 3 으로 진행.

---

## Step 3: 모듈 후보 자동 감지

`shared/module-detect.md` 를 Read tool 로 읽고, 그 모듈의 `## 플랫폼별 모듈 감지` 와 `## 모듈 메타정보 수집` 절차를 순서대로 실행한다.

결과는 `modules` 배열로 들고 있는다. 각 항목은 `{ name, path, file_count, has_namespace, depends_on, dependents, has_readme, recommend }` 형태 — **이 필드들은 module-detect.md 가 정의한다. 본 SKILL 에서 다시 정의하지 않는다.**

---

## Step 4: 휴리스틱 추천 + 사용자 [Y/n]

`shared/module-detect.md` 의 `## 추천 휴리스틱` 은 Step 3 에서 이미 적용돼 각 항목의 `recommend` 필드에 `Y` / `N` 디폴트가 들어 있다.

사용자에게 모듈 표를 출력한다. `#` 컬럼은 1-based 행 번호로, `[B]` 입력에서 사용한다.

```
| # | 모듈 | 파일 | 의존 → | 의존 ← | 추천 |
|---|------|------|--------|--------|------|
| 1 | :feature:home | 42 | 3 | 1 | Y |
| 2 | :core:util | 3  | 0 | 0 | N |
```

이어서 두 가지 입력 방식을 제안한다.

```
입력 방식을 선택하세요.
  [A] 모듈 1 개씩 [Y/n] 순차 확인
  [B] 한 번에 "예외만" 입력 — 추천 디폴트를 뒤집을 모듈 번호(표의 # 컬럼)를 콤마로 (예: 2, 5)
```

- `A` 선택 → 모듈 순서대로 한 줄씩 `[Y/n]` (디폴트는 `recommend` 값) 으로 묻는다.
- `B` 선택 → 사용자가 입력한 번호(표 `#` 컬럼, 1-based) 들에 해당하는 모듈만 `recommend` 값을 뒤집고 나머지는 디폴트 유지.

최종 포함 모듈을 `selected_modules` 배열로 확정한다.

---

## Step 5: progress 파일 생성 / resume

progress 파일 경로: `docs/superpowers/progress/harness-map.md`.

### 이미 존재하는 경우

Read 해서 미완료 (`- [ ]`) 항목이 1 개 이상 있으면 사용자에게 묻는다.

```
이전 실행이 중단됐습니다. 이어서 진행할까요? [Y/r]
  - 빈 입력 또는 Y → 이어서 진행 (미완료 모듈만)
  - r → 처음부터 다시 시작 (progress 파일 덮어씀)
```

- 빈 입력 또는 `Y` → 미완료 항목만 `selected_modules` 로 좁혀 Step 6 진행.
- `r` → progress 파일을 새 양식으로 덮어쓰고 Step 6 진행.

### 신규 작성

다음 양식으로 Write tool 로 생성한다.

```markdown
# /harness-map 진행

플랫폼: {Android/iOS/General}
감지된 모듈: {n} 개
선택된 모듈: {m} 개

## 진행 체크리스트
- [ ] :feature:home
- [ ] :feature:profile
- [x] :core:network
```

> 모듈 항목 순서는 `module-detect.md` 가 반환한 순서를 그대로 보존한다.

---

## Step 6: 모듈 1 개씩 처리

`shared/module-claude-template.md` 를 Read tool 로 읽는다. `selected_modules` 의 미완료 항목부터 순서대로 다음 절차를 반복한다.

1. **Q1 (역할) 자동 추론** — `module-claude-template.md` 의 `## 자동 추론 가이드` 의 Q1 절차로 한 줄 초안을 만든다. 사용자에게 보여주고 수정 또는 그대로 OK 받는다.
2. **Q4 (의존성) 자동 채움** — `depends_on` / `dependents` 를 그대로 옮겨 보여준다. 사용자가 수정 가능하나, 자동 그래프와 어긋나면 경고를 출력하고 한 번 더 확인을 받는다.
3. **Q2 / Q3 / Q5 명시 입력** — 한 번에 한 질문씩 순차로 묻는다. **Skip 불가.** 빈 답변을 자동으로 `해당 없음` 으로 대체하지 않는다 — 의도된 공백 vs 잊은 공백을 구분하기 위해 사용자가 직접 `해당 없음` 을 입력해야 다음으로 넘어간다.
4. `module-claude-template.md` 의 `## 모듈 CLAUDE.md 양식 (≤50 줄)` 대로 본문을 조립한다. 조립 직후 `wc -l` 로 줄 수를 측정하고, 50 줄 초과 시 같은 모듈의 `## 50 줄 한도 압축 규칙` 을 적용한다. 압축 발생 시 원문(압축 전) 은 progress 파일의 `### 백업 — {모듈명}` 섹션으로 남긴다.
5. `{path}/CLAUDE.md` 로 Write tool 저장. 기존 파일이 있으면 사용자에게 묻는다.

   ```
   {path}/CLAUDE.md 가 이미 존재합니다. 덮어쓸까요? [y/N]
   ```

   `y` → 덮어쓰기. 빈 입력 또는 `N` → 이 모듈은 skip 하고 progress 는 미완료로 둔다 (기존 파일은 절대 수정하지 않는다 — `harness/SKILL.md` 의 정책과 정합).
6. progress 파일의 해당 모듈 항목을 `- [x]` 로 갱신 (Edit tool).
7. 다음 모듈로 넘어가기 전에 묻는다.

   ```
   다음 모듈로 진행할까요? [Y/n]
   ```

   `N` 이면 즉시 중단. progress 파일의 미완료 항목은 그대로 남으므로, 다음 `/harness-map` 호출 시 Step 5 의 resume 분기에서 이어 받는다.

---

## Step 7: 인덱스 생성 + 루트 CLAUDE.md 패치

진입 조건은 두 가지다.

- (a) Step 6 의 모든 `selected_modules` 가 완료된 직후 → Step 7 자동 진행.
- (b) Step 6.7 에서 사용자가 `N` 으로 중단했고 1 개 이상 완료된 상태 → 중단 직후 한 번 묻는다.

  ```
  지금까지 완료된 모듈로 인덱스를 생성할까요? [y/N]
  ```

  `y` → Step 7 진행. 빈 입력 또는 `N` → Step 7 skip 하고 그대로 종료 (다음 `/harness-map` 호출 시 resume 분기에서 이어서 진행).

1. `shared/module-claude-template.md` 의 `## docs/MODULE_MAP.md 인덱스 양식` 대로 `docs/MODULE_MAP.md` 를 Write tool 로 생성/덮어쓰기 한다. 행 정렬은 `module-detect.md` 가 반환한 모듈 순서를 그대로 보존한다.
2. 루트 `CLAUDE.md` 를 Read 해서 마지막 줄에 `@docs/MODULE_MAP.md` 가 있는지 확인.
   - 이미 있으면 skip.
   - 없으면 Edit tool 로 파일 마지막에 `@docs/MODULE_MAP.md` 한 줄을 추가한다.
3. 사용자에게 안내한다.

   ```
   루트 CLAUDE.md 는 하네스 핵심 6 종 중 하나입니다.
   pre-commit Hook (block-harness-commit.sh) 으로 Claude 의 commit 이 자동 차단됩니다.
   IDE 에서 직접 검토 후 commit 해 주세요.
   ```

---

## Step 8: 완료 리포트

```
## /harness-map 완료 리포트
- 플랫폼: {Android / iOS / General}
- 감지 모듈: {n} 개 / 선택 모듈: {m} 개
- 생성: {모듈 CLAUDE.md 경로 목록}, docs/MODULE_MAP.md
- 루트 CLAUDE.md: { @docs/MODULE_MAP.md 추가 / 이미 존재 }
- 중단된 모듈: {있다면 목록 — 다음 /harness-map 호출 시 이어서 진행}

다음 단계:
  사용자가 IDE 에서 검토 후 직접 commit/push 하세요.
  ※ 루트 CLAUDE.md 는 Hook 으로 자동 commit 차단됩니다.
  ※ 모듈 CLAUDE.md 와 docs/MODULE_MAP.md 는 자동 commit 차단 대상이 아닙니다 (후속 spec).
```
