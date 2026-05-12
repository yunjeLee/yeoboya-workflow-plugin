---
name: harness-validate
description: harness 효과 측정 세션을 시작·종료한다. /harness-validate plan-start {T1|T2|T3} {none|root|module} 로 plan 작성 측정, /harness-validate plan-done 으로 종료. /harness-validate exec-start {T1|T2|T3} {none|root|module} 로 실행 측정, /harness-validate exec-done 으로 종료. 한 trial = plan 세션 + exec 세션. spec 은 모든 조건에 동일 입력으로 사용하고, plan 작성 자체가 harness 의 영향을 받게 두어 plan + 실행 전체 워크플로우에서 harness 효과를 측정. dalla 모듈 분리 작업 (T1 profile, T2 report, T3 webview) 측정용.
model: opus
---

# Harness-Validate Skill — harness 효과 측정 (n=1)

총 18 세션 = 3 task (T1 profile / T2 report / T3 webview) × 3 harness (none / root / module) × 2 phase (plan / exec).
**한 trial = plan 세션 + exec 세션.** 각 세션 종료 후 `/clear` → `exit` → 새 세션.

## 실험 설계 원칙

**spec 은 모든 조건에 동일하게 고정하고, plan 작성은 LLM 에게 맡긴다.** 하네스의 본래 목적은 프로젝트 컨텍스트 주입이며, 이는 plan 단계에서 가장 큰 영향을 줄 것으로 기대된다. 따라서 plan 자체를 측정 대상에 포함시켜 plan 품질 + 실행 효율 두 단계에서 하네스 효과를 본다.

phase 정의:

- **plan phase**: spec 을 입력해 LLM 이 plan 을 작성한다. `docs/superpowers/plans/T{N}-{harness}-generated.md` 로 저장. 코드 변경 없음.
- **exec phase**: 같은 trial 의 plan phase 에서 작성된 plan 을 입력해 LLM 이 실행한다. 기존 measurement 방식과 동일.

두 phase 는 **별도 세션** 으로 분리한다. 캐시 누적과 transcript 측정 정확도를 유지하기 위함.

## 트리거

- `/harness-validate plan-start {task-id} {harness}` — plan 작성 측정 시작
- `/harness-validate plan-done` — plan 작성 측정 종료 + 자동 수집 + 수동 입력 + 저장
- `/harness-validate exec-start {task-id} {harness}` — 실행 측정 시작
- `/harness-validate exec-done` — 실행 측정 종료 + 자동 수집 + 수동 입력 + 저장

### harness 정의

| harness | 적용 파일 |
|---------|----------|
| `none`   | root `CLAUDE.md` 만 |
| `root`   | root `CLAUDE.md` + `docs/*.md` |
| `module` | root `CLAUDE.md` + `docs/*.md` + 모듈별 `CLAUDE.md` |

### task 정의

| task | 작업 | 생성되는 plan 경로 (exec phase 입력) |
|------|------|-----------------------------------|
| T1 | profile 기능을 `:feature:feature_profile:{api,impl}` + `:data:data_profile:{api,impl}` 로 분리 | `docs/superpowers/plans/T1-{harness}-generated.md` |
| T2 | report 기능을 `:feature:feature_report:{api,impl}` + `:data:data_report:{api,impl}` 로 분리 | `docs/superpowers/plans/T2-{harness}-generated.md` |
| T3 | webview 기능을 `:feature:feature_webview:{api,impl}` + `:data:data_webview:{api,impl}` 로 분리 | `docs/superpowers/plans/T3-{harness}-generated.md` |

> spec / prompt 본문은 `docs/superpowers/validation/targets.json` 에 저장. plan-start / exec-start 가 해당 task 의 prompt 를 출력한다.

## 측정 항목

### 자동 (transcript 파싱, 두 phase 동일)
- `tool_call_total` + `tool_call_breakdown` (Read / Edit / Bash / Grep / Write 등)
- `input_tokens` / `output_tokens` / `cache_read_input_tokens` / `cache_creation_input_tokens`

### 수동 — plan phase (rubric 기반)
- `plan_module_structure_correct` [y/n]: 의도한 4 모듈 (`:feature:..:{api,impl}` × 2) 을 plan 이 명시했는지
- `plan_dependency_correct` [y/n]: 의존성 방향이 맞는지 (impl → api, feature → data:api 등)
- `plan_acceptance_coverage` [0~N]: acceptance 항목 중 plan 이 명시적으로 다루는 개수
- `plan_task_count` [숫자]: plan 의 Task 수 (자동 추출 후 사용자 확인)

### 수동 — exec phase (rubric 기반)
- `buildable` [y/n]: 빌드 통과 + acceptance 만족
- `hallucination_count`: 존재하지 않는 API / import / 함수 / 파일경로 등장 횟수
- `correction_prompt_count`: "다시 / 틀렸어 / 수정해줘" 류 보정 의도 메시지 수 (단순 후속 질문 제외)
- `repeated_mistake_count`: 한 trial 내 동일 카테고리 실수를 2 회 이상 지적해야 한 횟수

---

## plan-start 명령

### Step 1: 인자 검증

- `task-id`: T1 / T2 / T3
- `harness`: none / root / module

오류 시 출력 후 종료:
```
사용법: /harness-validate plan-start {T1|T2|T3} {none|root|module}
```

### Step 2: 신선한 세션 검증 (안전장치)

활성 transcript 의 user 메시지 수가 1 (= 현재 명령 자체) 을 초과하면 경고 후 종료한다.

```bash
PROJECT_DIR=$(pwd | sed 's|/|-|g')
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_DIR"
LATEST_JSONL=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST_JSONL" ]; then
  echo "transcript 파일을 찾지 못했습니다: $TRANSCRIPT_DIR"
  exit 1
fi

USER_MSG_COUNT=$(jq -s '[.[] | select(.type == "user")] | length' "$LATEST_JSONL")
```

`USER_MSG_COUNT > 1` 이면:
```
⚠ 이 세션에는 이미 user 메시지가 {N} 개 있습니다.
  측정은 새 세션의 첫 명령이어야 합니다.
  /clear → exit → 새 세션에서 다시 실행하세요.
```

### Step 3: targets.json 확인

`docs/superpowers/validation/targets.json` 이 없으면 템플릿을 생성하고 종료한다.

```json
{
  "T1": {
    "plan_prompt": "profile 기능을 새 모듈로 분리하기 위한 구현 plan 을 작성한다.\n\n요구사항:\n- 4 개 모듈로 분리: :feature:feature_profile:{api,impl}, :data:data_profile:{api,impl}\n- 패키지 kr.co.inforexseoul.radioproject.ui.profile 는 비워져야 함\n- 외부 노출 진입점은 api 의 interface 로 추상화, impl 에서 Hilt 바인딩 제공\n\nacceptance:\n- :feature:feature_profile:{api,impl}, :data:data_profile:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.profile 패키지 비어 있음\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.profile\" app/src/main/java/ 결과 0 건\n\n절차:\n1. superpowers:writing-plans 스킬을 사용한다.\n2. 결과 plan 을 docs/superpowers/plans/T1-{harness}-generated.md 에 저장한다.\n3. 코드는 작성하지 않는다 — plan 작성까지만.",

    "exec_prompt": "profile 기능을 새 모듈로 분리하는 작업이다.\n\n구현 plan 은 `docs/superpowers/plans/T1-{harness}-generated.md` 에 이미 작성되어 있다. 이 plan 을 그대로 따라 구현한다.\n\n절차 (반드시 지킬 것):\n1. plan 파일을 끝까지 읽어 전체 task 흐름을 파악한다.\n2. superpowers:subagent-driven-development 또는 superpowers:executing-plans 스킬로 plan 의 Task 를 순서대로 실행한다.\n3. plan 의 Task 순서를 변경하거나 건너뛰지 않는다. plan 에 없는 추가 추상화 / 리팩토링도 하지 않는다.\n4. 각 Task 의 checkbox 단계를 모두 완료한 뒤 다음 Task 로 넘어간다.\n\nacceptance:\n- :feature:feature_profile:{api,impl}, :data:data_profile:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.profile 패키지 비어 있음\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.profile\" app/src/main/java/ 결과 0 건"
  },

  "T2": {
    "plan_prompt": "report 기능을 새 모듈로 분리하기 위한 구현 plan 을 작성한다.\n\n요구사항:\n- 4 개 모듈로 분리: :feature:feature_report:{api,impl}, :data:data_report:{api,impl}\n- 패키지 kr.co.inforexseoul.radioproject.ui.report 는 비워져야 함\n- 외부 노출 상수 (ReportType, ReportFrom) 는 :feature:feature_report:api 로 이동\n- 외부 노출 진입점은 api 의 interface 로 추상화, impl 에서 Hilt 바인딩 제공\n\nacceptance:\n- :feature:feature_report:{api,impl}, :data:data_report:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.report 패키지 비어 있음\n- 외부 노출 상수 (ReportType, ReportFrom) 는 :feature:feature_report:api 로 이동\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.report\" app/src/main/java/ 결과 0 건\n\n절차:\n1. superpowers:writing-plans 스킬을 사용한다.\n2. 결과 plan 을 docs/superpowers/plans/T2-{harness}-generated.md 에 저장한다.\n3. 코드는 작성하지 않는다 — plan 작성까지만.",

    "exec_prompt": "report 기능을 새 모듈로 분리하는 작업이다.\n\n구현 plan 은 `docs/superpowers/plans/T2-{harness}-generated.md` 에 이미 작성되어 있다. 이 plan 을 그대로 따라 구현한다.\n\n절차 (반드시 지킬 것):\n1. plan 파일을 끝까지 읽어 전체 task 흐름을 파악한다.\n2. superpowers:subagent-driven-development 또는 superpowers:executing-plans 스킬로 plan 의 Task 를 순서대로 실행한다.\n3. plan 의 Task 순서를 변경하거나 건너뛰지 않는다. plan 에 없는 추가 추상화 / 리팩토링도 하지 않는다.\n4. 각 Task 의 checkbox 단계를 모두 완료한 뒤 다음 Task 로 넘어간다.\n\nacceptance:\n- :feature:feature_report:{api,impl}, :data:data_report:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.report 패키지 비어 있음\n- 외부 노출 상수 (ReportType, ReportFrom) 는 :feature:feature_report:api 로 이동\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.report\" app/src/main/java/ 결과 0 건"
  },

  "T3": {
    "plan_prompt": "webview 기능을 새 모듈로 분리하기 위한 구현 plan 을 작성한다.\n\n요구사항:\n- 4 개 모듈로 분리: :feature:feature_webview:{api,impl}, :data:data_webview:{api,impl}\n- 패키지 kr.co.inforexseoul.radioproject.ui.webview 는 비워져야 함\n- 외부 노출 진입점은 api 의 interface 로 추상화, impl 에서 Hilt 바인딩 제공\n\nacceptance:\n- :feature:feature_webview:{api,impl}, :data:data_webview:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.webview 패키지 비어 있음\n- 외부 노출 진입점은 :feature:feature_webview:api 의 interface 로 추상화하고 impl 에서 Hilt 바인딩 제공\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.webview\" app/src/main/java/ 결과 0 건\n\n절차:\n1. superpowers:writing-plans 스킬을 사용한다.\n2. 결과 plan 을 docs/superpowers/plans/T3-{harness}-generated.md 에 저장한다.\n3. 코드는 작성하지 않는다 — plan 작성까지만.",

    "exec_prompt": "webview 기능을 새 모듈로 분리하는 작업이다.\n\n구현 plan 은 `docs/superpowers/plans/T3-{harness}-generated.md` 에 이미 작성되어 있다. 이 plan 을 그대로 따라 구현한다.\n\n절차 (반드시 지킬 것):\n1. plan 파일을 끝까지 읽어 전체 task 흐름을 파악한다.\n2. superpowers:subagent-driven-development 또는 superpowers:executing-plans 스킬로 plan 의 Task 를 순서대로 실행한다.\n3. plan 의 Task 순서를 변경하거나 건너뛰지 않는다. plan 에 없는 추가 추상화 / 리팩토링도 하지 않는다.\n4. 각 Task 의 checkbox 단계를 모두 완료한 뒤 다음 Task 로 넘어간다.\n\nacceptance:\n- :feature:feature_webview:{api,impl}, :data:data_webview:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.webview 패키지 비어 있음\n- 외부 노출 진입점은 :feature:feature_webview:api 의 interface 로 추상화하고 impl 에서 Hilt 바인딩 제공\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.webview\" app/src/main/java/ 결과 0 건"
  }
}
```

```
✓ targets.json 템플릿을 생성했습니다.
  내용을 확인한 후 다시 실행하세요.
  경로: docs/superpowers/validation/targets.json
```

있으면 해당 task 의 `plan_prompt` 를 로드하고 `{harness}` 플레이스홀더를 치환한다.

### Step 4: 세션 파일 작성

```bash
mkdir -p docs/superpowers/validation docs/superpowers/plans
LINE_START=$(wc -l < "$LATEST_JSONL")
python3 - <<PY
import json
from datetime import datetime, timezone
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "phase": "plan",
  "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "transcript_path": "${LATEST_JSONL}",
  "line_start": ${LINE_START}
}
with open("docs/superpowers/validation/.session.json", "w") as f:
    json.dump(data, f, indent=2)
PY
```

### Step 5: 측정 시작 안내 + plan_prompt 출력

```
측정 시작 [{task-id} / harness={harness} / phase=plan]
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

  {plan_prompt — {harness} 치환 완료}

─────────────────────────────────────────
plan 작성 완료 → /harness-validate plan-done
```

---

## plan-done 명령

### Step 1: 세션 파일 확인

`docs/superpowers/validation/.session.json` 이 없거나 `phase != "plan"` 이면:
```
실행 중인 plan 측정 세션이 없습니다. 먼저 /harness-validate plan-start 를 실행하세요.
```

### Step 2: 생성된 plan 파일 확인

```bash
TASK_ID=$(jq -r '.task_id' docs/superpowers/validation/.session.json)
HARNESS=$(jq -r '.harness' docs/superpowers/validation/.session.json)
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"

if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  LLM 이 plan 작성을 완료한 후 다시 실행하세요."
  exit 1
fi
```

### Step 3: transcript slice + 자동 수집

기존 exec-done 의 Step 2 와 동일 로직 (transcript slice, tool 집계, 토큰 합산).

### Step 4: plan_task_count 자동 추출

```bash
# "## Task" 또는 "### Task" 라인 수 카운트, 실패 시 0
PLAN_TASK_COUNT=$(grep -cE '^#+\s+Task\b' "$PLAN_FILE" || echo 0)
```

### Step 5: 자동 수집 결과 표시 + rubric 출력

```
[자동 수집 결과]
tool_call_total: {TOOL_TOTAL}
tool_breakdown : {TOOL_BREAKDOWN}
tokens         :
  input              : {input_tokens}
  output             : {output_tokens}
  cache_read         : {cache_read_input_tokens}
  cache_creation     : {cache_creation_input_tokens}
plan_task_count (자동 추출): {PLAN_TASK_COUNT}

[채점 rubric — plan phase]
- plan_module_structure_correct: 의도한 4 모듈 (:feature:..:{api,impl} × 2) 을 plan 이 명시했는지
- plan_dependency_correct: 의존성 방향이 맞는지 (impl→api, feature→data:api)
- plan_acceptance_coverage: acceptance 항목 중 plan 이 명시적으로 다루는 개수
- plan_task_count: 자동 추출값을 검토하고 필요 시 수정
```

### Step 6: 4 개 수동 질문 순차

```
Q1. plan_module_structure_correct [y/n]:
Q2. plan_dependency_correct [y/n]:
Q3. plan_acceptance_coverage [숫자]:
Q4. plan_task_count [숫자, 자동값={PLAN_TASK_COUNT}]:
```

### Step 7: 결과 저장

저장 경로:
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-plan.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-plan.md
```

#### 7-1. .json (메트릭)

```json
{
  "timestamp": "2026-05-12T14:32:00Z",
  "task_id": "T1",
  "harness": "none",
  "phase": "plan",
  "plan_file": "docs/superpowers/plans/T1-none-generated.md",
  "automated": {
    "tool_call_total": 0,
    "tool_call_breakdown": { "Read": 0, "Edit": 0, "Bash": 0, "Grep": 0, "Write": 0 },
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0
  },
  "manual": {
    "plan_module_structure_correct": true,
    "plan_dependency_correct": true,
    "plan_acceptance_coverage": 4,
    "plan_task_count": 5
  }
}
```

#### 7-2. .md (채점용 transcript markdown)

`/tmp/harness-validate-slice.jsonl` 을 사람이 읽기 좋은 markdown 으로 변환 (변환 규칙은 본 문서 끝의 공통 변환 스크립트 참조).

### Step 8: 세션 파일 정리 + 다음 phase 안내

```bash
rm docs/superpowers/validation/.session.json /tmp/harness-validate-slice.jsonl
```

```
✓ plan 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-plan.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-plan.md
  생성 plan: docs/superpowers/plans/{task}-{harness}-generated.md

다음 단계 (exec phase):
  1. /clear
  2. exit
  3. 새 세션 시작 (동일 worktree)
  4. /harness-validate exec-start {task} {harness}
```

---

## exec-start 명령

### Step 1: 인자 검증

`/harness-validate plan-start` 와 동일.

### Step 2: 신선한 세션 검증

`/harness-validate plan-start` Step 2 와 동일.

### Step 3: plan 파일 존재 확인

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  먼저 /harness-validate plan-start {task} {harness} 를 완료하세요."
  exit 1
fi
```

### Step 4: targets.json 에서 exec_prompt 로드

`{harness}` 치환 후 출력 대상으로 보관.

### Step 5: 세션 파일 작성

phase 만 `"exec"` 로 다르고 plan-start Step 4 와 동일.

### Step 6: 측정 시작 안내 + exec_prompt 출력

```
측정 시작 [{task-id} / harness={harness} / phase=exec]
─────────────────────────────────────────
사용할 plan: {PLAN_FILE}

아래 prompt 를 그대로 입력하세요:

  {exec_prompt — {harness} 치환 완료}

─────────────────────────────────────────
완료 → acceptance 검증 → /harness-validate exec-done
```

---

## exec-done 명령

### Step 1: 세션 파일 확인

`.session.json` 의 `phase != "exec"` 이면:
```
실행 중인 exec 측정 세션이 없습니다. 먼저 /harness-validate exec-start 를 실행하세요.
```

### Step 2: transcript slice + 자동 수집

```bash
SESSION_FILE=docs/superpowers/validation/.session.json
TRANSCRIPT=$(jq -r '.transcript_path' $SESSION_FILE)
LINE_START=$(jq -r '.line_start' $SESSION_FILE)
LINE_END=$(wc -l < "$TRANSCRIPT")
SLICE=/tmp/harness-validate-slice.jsonl

sed -n "$((LINE_START + 1)),${LINE_END}p" "$TRANSCRIPT" > "$SLICE"

TOOL_TOTAL=$(jq -s '
  [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length
' "$SLICE")

TOOL_BREAKDOWN=$(jq -s -c '
  [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name]
  | group_by(.) | map({key: .[0], value: length}) | from_entries
' "$SLICE")

TOKENS=$(jq -s -c '
  [.[] | select(.type == "assistant") | .message.usage]
  | reduce .[] as $u (
      {input_tokens:0, output_tokens:0, cache_read_input_tokens:0, cache_creation_input_tokens:0};
      .input_tokens             += ($u.input_tokens             // 0)
      | .output_tokens          += ($u.output_tokens            // 0)
      | .cache_read_input_tokens += ($u.cache_read_input_tokens // 0)
      | .cache_creation_input_tokens += ($u.cache_creation_input_tokens // 0)
    )
' "$SLICE")
```

### Step 3: 자동 수집 결과 표시 + rubric 출력

```
[자동 수집 결과]
tool_call_total: {TOOL_TOTAL}
tool_breakdown : {TOOL_BREAKDOWN}
tokens         :
  input              : {input_tokens}
  output             : {output_tokens}
  cache_read         : {cache_read_input_tokens}
  cache_creation     : {cache_creation_input_tokens}

[채점 rubric — exec phase]
- buildable: 빌드 통과 + 요청한 acceptance 만족 시 y
- hallucination: 존재하지 않는 API / import / 함수 / 파일경로 등장 횟수
- correction_prompt: "다시 / 틀렸어 / 수정해줘" 류 보정 의도 메시지 수
                    (단순 후속 질문 제외)
- repeated_mistake: 한 trial 내 동일 카테고리 실수를 2 회 이상 지적해야 한 횟수
```

### Step 4: 4 개 수동 질문 순차

```
Q1. buildable [y/n]:
Q2. hallucination_count [숫자]:
Q3. correction_prompt_count [숫자]:
Q4. repeated_mistake_count [숫자]:
```

### Step 5: 결과 저장

저장 경로:
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-exec.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-exec.md
```

#### 5-1. .json (메트릭)

```json
{
  "timestamp": "2026-05-12T14:32:00Z",
  "task_id": "T1",
  "harness": "none",
  "phase": "exec",
  "plan_file": "docs/superpowers/plans/T1-none-generated.md",
  "automated": {
    "tool_call_total": 0,
    "tool_call_breakdown": { "Read": 0, "Edit": 0, "Bash": 0, "Grep": 0, "Write": 0 },
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0
  },
  "manual": {
    "buildable": true,
    "hallucination_count": 0,
    "correction_prompt_count": 0,
    "repeated_mistake_count": 0
  }
}
```

#### 5-2. .md (채점용 transcript markdown)

본 문서 끝의 공통 변환 스크립트 사용.

### Step 6: 세션 파일 정리 + 다음 trial 안내

```bash
rm docs/superpowers/validation/.session.json /tmp/harness-validate-slice.jsonl
```

```
✓ exec 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-exec.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-exec.md

이 trial (task={task}, harness={harness}) 완료.

다음 trial 준비:
  1. /clear
  2. exit
  3. 새 세션 시작 (다음 task / harness worktree)
  4. /harness-validate plan-start {다음 task} {harness}

채점 안내:
  18 세션 (9 trial × 2 phase) 이 모두 끝난 뒤 .md 파일을 열어 rubric 을 채점하세요.
  현재 .json 의 manual 항목은 done 시 입력한 값입니다 —
  채점 결과가 다르면 직접 수정해 정합성을 맞춥니다.
```

---

## 공통: transcript → markdown 변환 스크립트

plan-done / exec-done 의 채점용 .md 생성에 공통으로 사용한다.

변환 규칙:
- 각 jsonl entry 를 `## Turn {N} (user|assistant)` 단위로 끊는다.
- assistant turn 안에 `tool_use` 가 여러 개면 `### Tool: {name}` 로 모두 표시.
- tool_use 의 `input` 에서 핵심 인자만 보여준다 (Bash → `command`, Read/Edit → `file_path`, Grep → `pattern`).
- 각 인자값이 200 자를 넘으면 첫 200 자 + ` (... 생략 N 자)` 표기.
- tool_result 는 첫 20 줄까지만 보여주고 그 이상이면 `(... 생략 N 줄)` 표기.

```bash
python3 - <<'PY' > /tmp/harness-validate.md
import json

TURN_LIMIT_ARG = 200
TURN_LIMIT_RES = 20  # lines

with open("/tmp/harness-validate-slice.jsonl") as f:
    entries = [json.loads(line) for line in f if line.strip()]

with open("docs/superpowers/validation/.session.json") as f:
    sess = json.load(f)

print(f"# {sess['task_id']} / {sess['harness']} / {sess['phase']} — {sess['started_at']}\n")

turn = 0
for e in entries:
    etype = e.get("type")
    msg = e.get("message", {})
    if etype == "user":
        turn += 1
        content = msg.get("content")
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            parts = []
            for c in content:
                if c.get("type") == "text":
                    parts.append(c.get("text", ""))
                elif c.get("type") == "tool_result":
                    res = c.get("content", "")
                    if isinstance(res, list):
                        res = "\n".join(x.get("text", "") for x in res if x.get("type") == "text")
                    lines = (res or "").split("\n")
                    if len(lines) > TURN_LIMIT_RES:
                        res = "\n".join(lines[:TURN_LIMIT_RES]) + f"\n(... 생략 {len(lines) - TURN_LIMIT_RES} 줄)"
                    parts.append(f"### Tool result\n```\n{res}\n```")
            text = "\n\n".join(parts)
        else:
            text = ""
        print(f"## Turn {turn} (user)\n\n{text}\n")
    elif etype == "assistant":
        turn += 1
        content = msg.get("content", [])
        text_parts, tool_parts = [], []
        for c in content:
            if c.get("type") == "text":
                text_parts.append(c.get("text", ""))
            elif c.get("type") == "tool_use":
                name = c.get("name", "?")
                inp = c.get("input", {})
                key_args = []
                for k in ("command", "file_path", "pattern", "old_string", "new_string", "content"):
                    if k in inp:
                        v = str(inp[k])
                        if len(v) > TURN_LIMIT_ARG:
                            v = v[:TURN_LIMIT_ARG] + f" (... 생략 {len(v) - TURN_LIMIT_ARG} 자)"
                        key_args.append(f"- **{k}**: `{v}`")
                tool_parts.append(f"### Tool: {name}\n" + "\n".join(key_args))
        body = "\n\n".join(text_parts + tool_parts)
        print(f"## Turn {turn} (assistant)\n\n{body}\n")
PY

mv /tmp/harness-validate.md docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-{phase}.md
```

> 변환 스크립트는 transcript jsonl 의 정확한 구조에 따라 미세 조정이 필요할 수 있다. 첫 trial 에서 한 번 결과 .md 를 직접 열어 가독성을 확인하고, 필요 시 변환 규칙을 다듬는다.

---

## 운영 가이드 (측정자용)

### 브랜치 / Worktree 구성

dalla 프로젝트에 미리 만든 3 브랜치를 worktree 로 펼친다. 각 브랜치는 측정 시작 전에 의도된 harness 상태로 commit 되어 있어야 한다.

| 브랜치 | harness 상태 | worktree 디렉토리 |
|--------|-------------|------------------|
| `plugin_none`   | root `CLAUDE.md` 만 (docs/ + 모듈 CLAUDE.md 삭제 commit) | `.worktrees/plugin_none` |
| `plugin_root`   | root `CLAUDE.md` + `docs/*.md` (모듈 CLAUDE.md 삭제 commit) | `.worktrees/plugin_root` |
| `plugin_module` | + 모듈별 `CLAUDE.md` (전부 유지) | `.worktrees/plugin_module` |

```bash
cd /Users/iyunje/AndroidStudio/dalla
git worktree add .worktrees/plugin_none   plugin_none
git worktree add .worktrees/plugin_root   plugin_root
git worktree add .worktrees/plugin_module plugin_module
```

각 터미널이 각 worktree 디렉토리에서 독립 세션으로 측정한다.
측정 종료 후 정리:

```bash
git worktree remove .worktrees/plugin_none
git worktree remove .worktrees/plugin_root
git worktree remove .worktrees/plugin_module
```

### 한 trial 의 흐름 (plan 세션 → exec 세션)

```
[plan 세션]
새 세션 시작 (해당 worktree 디렉토리)
  → /harness-validate plan-start {task} {harness}
  → targets.json 의 plan_prompt 를 그대로 입력
    (LLM 이 spec 기반으로 plan 작성, docs/superpowers/plans/{task}-{harness}-generated.md 저장)
  → /harness-validate plan-done
  → 자동 수집 표시 + plan rubric 4 개 입력
  → /clear → exit

[exec 세션]
새 세션 시작 (동일 worktree 디렉토리)
  → /harness-validate exec-start {task} {harness}
    (plan 파일 존재 확인)
  → targets.json 의 exec_prompt 를 그대로 입력
    (LLM 이 plan 을 그대로 따라 실행)
  → 작업 진행 (필요 시 보정 prompt)
  → acceptance 검증 (빌드 / 동작 확인)
  → /harness-validate exec-done
  → 자동 수집 표시 + exec rubric 4 개 입력
  → /clear → exit → 다음 trial
```

> exec 보정 prompt 는 plan 외 작업을 시키는 것이 아니라 "plan 의 Task X 를 다시 확인해줘" 류로 plan 범위 내에서만 사용한다. plan 에서 벗어난 추가 작업을 시키면 측정 일관성이 깨진다.

### task 단위 동기화 권장

T1 (profile) 의 3 harness × 2 phase = 6 세션을 모두 끝낸 뒤 T2, 그 다음 T3 순서. 즉 (task × harness × phase) 가 아닌 task 단위로 다 같이 진행. 캐시 / 채점 일관성 확보 목적.

### 채점 운영

- 채점은 18 세션이 모두 끝난 뒤 `.md` 파일들을 차례로 열어 일괄 진행
- plan 채점은 `-plan.md` 와 `docs/superpowers/plans/{task}-{harness}-generated.md` 를 같이 본다
- exec 채점은 `-exec.md` 만 본다
- 가능하면 파일명에서 harness 부분을 일시적으로 가리고 채점 (간이 blinding)
- correction_prompt / repeated_mistake 의 카테고리 분류는 9 trial 동안 일관 기준 유지
- done 시 입력한 manual 값과 일괄 채점 결과가 다르면 .json 의 manual 항목을 수정

### 결과 수합

각 worktree 에 흩어진 결과를 한 곳에 모아 분석:

```bash
DALLA=/Users/iyunje/AndroidStudio/dalla
mkdir -p "$DALLA-validation-results"
cp "$DALLA/.worktrees/plugin_none/docs/superpowers/validation/"*.{json,md}   "$DALLA-validation-results/" 2>/dev/null
cp "$DALLA/.worktrees/plugin_root/docs/superpowers/validation/"*.{json,md}   "$DALLA-validation-results/" 2>/dev/null
cp "$DALLA/.worktrees/plugin_module/docs/superpowers/validation/"*.{json,md} "$DALLA-validation-results/" 2>/dev/null
cp "$DALLA/.worktrees/plugin_none/docs/superpowers/plans/"*-generated.md     "$DALLA-validation-results/" 2>/dev/null
cp "$DALLA/.worktrees/plugin_root/docs/superpowers/plans/"*-generated.md     "$DALLA-validation-results/" 2>/dev/null
cp "$DALLA/.worktrees/plugin_module/docs/superpowers/plans/"*-generated.md   "$DALLA-validation-results/" 2>/dev/null
```

### n=1 한계

각 (task × harness) 조합당 1 회 측정이라 LLM 분산과 harness 효과를 통계적으로 분리할 수 없다.
큰 차이 (예: 도구 호출 50% 이상 감소, plan_module_structure 정/오 명확) 만 directional 결론 대상이며, 작은 차이 (5~10% 토큰 차) 는 분산 가능성을 배제할 수 없다.

특히 plan phase 는 LLM 분산이 더 클 수 있다는 점을 인식하고, 큰 정성적 차이 (plan 구조 / acceptance 누락 여부) 를 우선 본다.
