---
name: harness-validate-clear
description: brainstorming 기반 plan 작성 + Task 단위 세션 분할(clear) 워크플로우로 harness 효과를 측정한다. plan 세션에서 brainstorming으로 Task 구조를 결정한 뒤, exec 세션을 Task 하나씩 분리해 각 Task 완료 후 /clear한다. /harness-validate-clear plan-start {T-A|T-B} {none|root|module} 로 시작.
model: opus
---

# Harness-Validate-Clear

## 워크플로우 정의

```
[plan 세션]
  brainstorming → Task 수·경계 결정 → plan 작성 (## Task N 헤더)
  → plan-done → /clear → exit

[exec 세션 — Task 1]
  task-start {task} {harness} 1
  → 해당 Task 구현 (inline 전용)
  → task-done → /clear → exit

[exec 세션 — Task 2 ... Task N-1]
  task-start {task} {harness} {N}
  → 해당 Task 구현 (inline 전용)
  → task-done → /clear → exit

[exec 세션 — 마지막 Task]
  task-start {task} {harness} {N}
  → 해당 Task 구현 + acceptance 전체 검증
  → exec-done → /clear → exit
```

**inline 전용**: 모든 코드 실행은 현재 세션에서 직접 수행한다. subagent 분산 실행 금지.

## 명령 체계

| 명령 | 용도 |
|------|------|
| `plan-start {T-A\|T-B} {none\|root\|module}` | plan 측정 시작 (brainstorming 포함) |
| `plan-done` | plan 측정 종료 + 저장 |
| `task-start {T-A\|T-B} {none\|root\|module} {task-no}` | Task N 세션 시작 |
| `task-done` | Task 중간 종료 + 누적 저장 |
| `exec-done` | 마지막 Task 종료 + 전체 집계 |

---

## plan-start 명령

### Step 1: 인자 검증

- `task-id`: T-A / T-B
- `harness`: none / root / module

오류 시:
```
사용법: /harness-validate-clear plan-start {T-A|T-B} {none|root|module}
```

### Step 2: 신선한 세션 검증

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

### Step 3: 디렉토리 생성 + 세션 파일 작성

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

### Step 4: plan prompt 출력

`{harness}` 를 실제 값으로 치환해 출력한다.

**T-A plan prompt:**

```
측정 시작 [T-A / harness={harness} / phase=plan]
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

feature_report 기능을 복구하기 위한 구현 plan 을 작성한다.

배경:
- feature_report:impl 과 data_report:impl 의 구현 파일이 삭제된 상태다.
- feature_report:api (ReportLauncher, ReportFrom, ReportType) 는 그대로 있다.
- data_report:api (ReportDataSource, ReportRepository interface) 는 그대로 있다.
- domain UseCase (ReqReportUserUseCase, ReqReportClipUserUseCase) 는 그대로 있다.

복구해야 할 파일:
- feature_report:impl
  - ReportDialog (신고 진입 Dialog, ReportFrom 에 따라 block/describe 분기)
  - ReportViewModel (신고 플래그 관리)
  - ReportLauncherImpl (ReportLauncher 구현체, Hilt 바인딩)
  - di/ReportFeatureModule (ReportLauncher Hilt 모듈)
  - block/ReportBlockFragment + ReportBlockViewModel (차단 UI)
  - describe/ReportDescribeFragment + ReportDescribeViewModel (신고 내용 입력 UI)
- data_report:impl
  - ReportService (Retrofit API interface)
  - ReportDataSourceImpl (ReportDataSource 구현체)
  - ReportRepositoryImpl (ReportRepository 구현체)
  - di/ReportDataModule + di/ProvidesReportService (Hilt DI 모듈)

요구사항:
- 기존 feature_profile / data_profile 의 패턴을 따른다
- StateFlow 기반 상태 관리 (mutableResultState + asStateFlow)
- Hilt constructor injection 사용
- BaseDialogFragment / BaseViewModel 상속 유지

acceptance:
- ./gradlew :feature:feature_report:impl:compileDebugKotlin 통과
- ./gradlew :data:data_report:impl:compileDebugKotlin 통과
- ./gradlew :app:assembleDebug 통과
- ReportLauncher.show() 호출 시 ReportDialog 가 열린다

절차:
1. superpowers:brainstorming 스킬로 복구 작업을 분석하고 Task 수와 경계를 결정한다.
2. superpowers:writing-plans 스킬로 plan 을 작성한다.
3. 결과 plan 을 docs/superpowers/plans/T-A-{harness}-clear-generated.md 에 저장한다.
4. plan 의 각 Task 는 반드시 "## Task N" 형식 헤더로 구분한다
   (task-start 가 이 헤더를 기준으로 세션을 분할하기 때문).
5. 코드는 작성하지 않는다 — plan 작성까지만.

─────────────────────────────────────────
plan 작성 완료 → /harness-validate-clear plan-done
```

**T-B plan prompt:**

```
측정 시작 [T-B / harness={harness} / phase=plan]
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

SplashActivity / SplashViewModel 에 존재하는 버그 3개를 진단하고 수정한다.

버그 목록:
1. [Bug 1] 음원 파일 다운로드 미실행
   - 증상: .mp3 / .m4a / .wav 파일이 다운로드되지 않는다. 에러 로그 없음.
   - 위치 힌트: SplashViewModel 의 downloadFile 관련 코드

2. [Bug 2] Firebase Remote Config 실패 시 무한 로딩
   - 증상: Firebase 오류 발생 시 앱이 스플래시 화면에서 멈춘다.
   - 위치 힌트: SplashActivity 의 앱 초기화 흐름

3. [Bug 3] 특정 서버 에러 시 스플래시 이후 화면으로 진행 안 됨
   - 증상: 첫 번째 API 는 성공하지만 두 번째 API 실패 시 로딩 상태에 고착.
   - 위치 힌트: SplashViewModel 의 데이터 페칭 로직

요구사항:
- 각 버그의 원인을 코드에서 명확히 확인한 후 수정한다.
- 수정은 최소 범위로 한다 (해당 버그 원인 코드만 변경).
- 다른 파일 / 기능에 영향을 주지 않는다.

acceptance:
- Bug 1: SplashViewModel.downloadFile() 에서 DownloadManager.enqueue() 가 호출된다
- Bug 2: Firebase 실패 시에도 앱 초기화가 계속 진행된다 (onComplete 호출)
- Bug 3: getSplashDataUseCase 실패 시 splashDataState 가 Error 로 전환된다
- ./gradlew :feature:feature_splash:impl:compileDebugKotlin 통과

절차:
1. superpowers:brainstorming 스킬로 버그 수정 작업을 분석하고 Task 수와 경계를 결정한다.
2. superpowers:writing-plans 스킬로 plan 을 작성한다.
3. 결과 plan 을 docs/superpowers/plans/T-B-{harness}-clear-generated.md 에 저장한다.
4. plan 의 각 Task 는 반드시 "## Task N" 형식 헤더로 구분한다
   (task-start 가 이 헤더를 기준으로 세션을 분할하기 때문).
5. 코드는 작성하지 않는다 — plan 작성까지만.

─────────────────────────────────────────
plan 작성 완료 → /harness-validate-clear plan-done
```

---

## plan-done 명령

### Step 1: 세션 파일 확인

`docs/superpowers/validation/.session.json` 이 없거나 `phase != "plan"` 이면:
```
실행 중인 plan 측정 세션이 없습니다. 먼저 /harness-validate-clear plan-start 를 실행하세요.
```

### Step 2: plan 파일 존재 확인

```bash
TASK_ID=$(jq -r '.task_id' docs/superpowers/validation/.session.json)
HARNESS=$(jq -r '.harness' docs/superpowers/validation/.session.json)
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-clear-generated.md"

if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  LLM 이 plan 작성을 완료한 후 다시 실행하세요."
  exit 1
fi
```

### Step 3: transcript slice + 자동 수집

```bash
TRANSCRIPT=$(jq -r '.transcript_path' docs/superpowers/validation/.session.json)
LINE_START=$(jq -r '.line_start' docs/superpowers/validation/.session.json)
LINE_END=$(wc -l < "$TRANSCRIPT")
SLICE=/tmp/harness-validate-clear-slice.jsonl

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
      .input_tokens              += ($u.input_tokens             // 0)
      | .output_tokens           += ($u.output_tokens            // 0)
      | .cache_read_input_tokens += ($u.cache_read_input_tokens  // 0)
      | .cache_creation_input_tokens += ($u.cache_creation_input_tokens // 0)
    )
' "$SLICE")
```

### Step 4: plan_task_count 자동 추출

```bash
PLAN_TASK_COUNT=$(grep -cE '^## Task [0-9]+' "$PLAN_FILE" || echo 0)
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
```

**T-A 채점 rubric:**
```
[채점 rubric — T-A plan phase]
- plan_layer_structure_correct [y/n]: data → feature 계층 순서 + ## Task N 헤더 존재
- plan_dependency_correct [y/n]: DI 모듈, Hilt 바인딩, 의존성 방향 포함 여부
- plan_acceptance_coverage [0~4]: acceptance 4개 중 plan 이 명시적으로 다루는 개수
- plan_task_count [숫자]: 자동 추출값 검토 후 필요 시 수정
```

**T-B 채점 rubric:**
```
[채점 rubric — T-B plan phase]
- plan_bug_diagnosis_correct [0~3]: 3개 버그 중 원인을 올바르게 진단한 개수
- plan_fix_strategy_correct [0~3]: 3개 버그 중 올바른 수정 방향을 제시한 개수
- plan_acceptance_coverage [0~4]: acceptance 4개 중 plan 이 명시적으로 다루는 개수
- plan_task_count [숫자]: 자동 추출값 검토 후 필요 시 수정
```

### Step 6: 수동 질문 순차

**T-A:**
```
Q1. plan_layer_structure_correct [y/n]:
Q2. plan_dependency_correct [y/n]:
Q3. plan_acceptance_coverage [숫자 0~4]:
Q4. plan_task_count [숫자, 자동값={PLAN_TASK_COUNT}]:
```

**T-B:**
```
Q1. plan_bug_diagnosis_correct [숫자 0~3]:
Q2. plan_fix_strategy_correct [숫자 0~3]:
Q3. plan_acceptance_coverage [숫자 0~4]:
Q4. plan_task_count [숫자, 자동값={PLAN_TASK_COUNT}]:
```

### Step 7: 결과 저장

저장 경로:
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-clear-plan.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-clear-plan.md
```

**T-A .json 예시:**
```json
{
  "timestamp": "2026-05-15T00:00:00Z",
  "task_id": "T-A",
  "harness": "none",
  "workflow": "clear",
  "phase": "plan",
  "plan_file": "docs/superpowers/plans/T-A-none-clear-generated.md",
  "automated": {
    "tool_call_total": 0,
    "tool_call_breakdown": { "Read": 0, "Edit": 0, "Bash": 0, "Write": 0 },
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0
  },
  "manual": {
    "plan_layer_structure_correct": true,
    "plan_dependency_correct": true,
    "plan_acceptance_coverage": 4,
    "plan_task_count": 4
  }
}
```

**T-B .json 예시:**
```json
{
  "timestamp": "2026-05-15T00:00:00Z",
  "task_id": "T-B",
  "harness": "none",
  "workflow": "clear",
  "phase": "plan",
  "plan_file": "docs/superpowers/plans/T-B-none-clear-generated.md",
  "automated": {
    "tool_call_total": 0,
    "tool_call_breakdown": { "Read": 0, "Edit": 0, "Bash": 0, "Write": 0 },
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0
  },
  "manual": {
    "plan_bug_diagnosis_correct": 3,
    "plan_fix_strategy_correct": 3,
    "plan_acceptance_coverage": 4,
    "plan_task_count": 3
  }
}
```

채점용 .md 는 본 문서 끝 **공통 transcript → markdown 변환 스크립트** 사용.

### Step 8: 세션 파일 정리 + 다음 단계 안내

```bash
rm docs/superpowers/validation/.session.json /tmp/harness-validate-clear-slice.jsonl
```

```
✓ plan 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-clear-plan.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-clear-plan.md
  생성 plan: docs/superpowers/plans/{task}-{harness}-clear-generated.md

다음 단계 (exec — Task 1 세션):
  1. /clear → exit
  2. 새 세션 시작 (동일 worktree)
  3. /harness-validate-clear task-start {task} {harness} 1
```

---

## task-start 명령

### Step 1: 인자 검증

- `task-id`: T-A / T-B
- `harness`: none / root / module
- `task-no`: 1 이상의 정수

오류 시:
```
사용법: /harness-validate-clear task-start {T-A|T-B} {none|root|module} {task번호}
```

### Step 2: 신선한 세션 검증

plan-start Step 2 와 동일.

### Step 3: plan 파일 존재 확인

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-clear-generated.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  먼저 /harness-validate-clear plan-start {task} {harness} 를 완료하세요."
  exit 1
fi
```

### Step 4: task 수 확인 + task-no 범위 검증

```bash
TOTAL_TASKS=$(grep -cE '^## Task [0-9]+' "$PLAN_FILE" || echo 0)

if [ "$TASK_NO" -gt "$TOTAL_TASKS" ]; then
  echo "⚠ task-no ${TASK_NO} 가 plan 의 Task 수 ${TOTAL_TASKS} 를 초과합니다."
  exit 1
fi
```

### Step 5: accumulator 초기화 (task-no 1일 때만)

```bash
ACCUM="docs/superpowers/validation/.task-accumulator.json"

if [ "${TASK_NO}" = "1" ]; then
  python3 - <<PY
import json
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "workflow": "clear",
  "total_tasks": ${TOTAL_TASKS},
  "next_task": 1,
  "tasks": []
}
with open("$ACCUM", "w") as f:
    json.dump(data, f, indent=2)
PY
else
  if [ ! -f "$ACCUM" ]; then
    echo "⚠ task accumulator 가 없습니다. task 1 부터 시작하세요."
    exit 1
  fi
fi
```

### Step 6: 세션 파일 작성

```bash
LINE_START=$(wc -l < "$LATEST_JSONL")

python3 - <<PY
import json
from datetime import datetime, timezone
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "workflow": "clear",
  "phase": "task",
  "task_no": ${TASK_NO},
  "total_tasks": ${TOTAL_TASKS},
  "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "transcript_path": "${LATEST_JSONL}",
  "line_start": ${LINE_START}
}
with open("docs/superpowers/validation/.session.json", "w") as f:
    json.dump(data, f, indent=2)
PY
```

### Step 7: task 섹션 추출 + prompt 출력

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-clear-generated.md"
NEXT=$((TASK_NO + 1))
IS_LAST=$( [ "$TASK_NO" = "$TOTAL_TASKS" ] && echo "true" || echo "false" )

# plan 에서 Task N 섹션 추출 (다음 ## Task 헤더 또는 파일 끝까지)
TASK_CONTENT=$(awk \
  "/^## Task ${TASK_NO}$/{found=1; next} \
   found && /^## Task [0-9]+/{exit} \
   found{print}" "$PLAN_FILE" | head -80)

# 이전 task 완료 문구 (task-no >= 2 일 때)
if [ "$TASK_NO" -ge 2 ]; then
  PREV_DONE="Task 1 ~ $((TASK_NO - 1)) 은 이미 완료된 상태다."
else
  PREV_DONE=""
fi
```

출력 형식:

```
측정 시작 [{TASK_ID} / harness={HARNESS} / task={TASK_NO}/{TOTAL_TASKS}]
사용할 plan: {PLAN_FILE}
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

{TASK_ID} 작업 중 Task {TASK_NO} / {TOTAL_TASKS} 을 진행한다.
{PREV_DONE}

plan 파일: {PLAN_FILE}
이번 세션에서 구현할 범위: plan 의 아래 ## Task {TASK_NO} 섹션을 따른다.

--- plan Task {TASK_NO} 시작 ---
{TASK_CONTENT}
--- plan Task {TASK_NO} 끝 ---

절차:
1. 위 plan 섹션 전체를 숙지한다.
2. superpowers:executing-plans 스킬을 인라인으로 사용해 실행한다
   (subagent 분산 실행 금지 — 현재 세션에서 직접 실행).
3. Task {TASK_NO} 완료 후 세션을 종료한다.
[IS_LAST=true 일 때만 추가]
4. 완료 후 아래 acceptance 를 전체 검증한다:
   [task-id 별 acceptance 목록 삽입]

─────────────────────────────────────────
[IS_LAST=false] 완료 → /harness-validate-clear task-done
[IS_LAST=true]  ⚠ 마지막 Task — 완료 후 exec-done 으로 전체 집계
                완료 → acceptance 검증 → /harness-validate-clear exec-done
```

**task-id 별 acceptance 목록 (IS_LAST=true 일 때 삽입):**

T-A:
```
- ./gradlew :feature:feature_report:impl:compileDebugKotlin 통과
- ./gradlew :data:data_report:impl:compileDebugKotlin 통과
- ./gradlew :app:assembleDebug 통과
- ReportLauncher.show() 호출 시 ReportDialog 가 열린다
```

T-B:
```
- Bug 1: SplashViewModel.downloadFile() 에서 DownloadManager.enqueue() 가 호출된다
- Bug 2: Firebase 실패 시에도 앱 초기화가 계속 진행된다 (onComplete 호출)
- Bug 3: getSplashDataUseCase 실패 시 splashDataState 가 Error 로 전환된다
- ./gradlew :feature:feature_splash:impl:compileDebugKotlin 통과
```

---

## task-done 명령 (중간 Task)

### Step 1: 세션 파일 확인

`phase == "task"` 인지 확인. 아니면:
```
실행 중인 task 측정 세션이 없습니다. /harness-validate-clear task-start 를 먼저 실행하세요.
```

마지막 task 여부 확인:

```bash
TASK_NO=$(jq -r '.task_no' docs/superpowers/validation/.session.json)
TOTAL_TASKS=$(jq -r '.total_tasks' docs/superpowers/validation/.session.json)

if [ "$TASK_NO" = "$TOTAL_TASKS" ]; then
  echo "⚠ 이 Task 는 마지막 Task 입니다 (${TASK_NO}/${TOTAL_TASKS})."
  echo "  task-done 대신 /harness-validate-clear exec-done 으로 전체 집계하세요."
  exit 1
fi
```

### Step 2: transcript slice + 자동 수집

plan-done Step 3 와 동일 로직. `SLICE=/tmp/harness-validate-clear-slice.jsonl`.

### Step 3: accumulator 에 현재 task 메트릭 추가

```bash
ACCUM="docs/superpowers/validation/.task-accumulator.json"

python3 - <<PY
import json

with open("$ACCUM") as f:
    acc = json.load(f)

acc["tasks"].append({
    "task_no": ${TASK_NO},
    "tool_call_total": ${TOOL_TOTAL},
    "tool_call_breakdown": ${TOOL_BREAKDOWN},
    "tokens": ${TOKENS}
})
acc["next_task"] = ${TASK_NO} + 1

with open("$ACCUM", "w") as f:
    json.dump(acc, f, indent=2)
PY
```

### Step 4: 자동 수집 결과 표시

```
[Task {N} 자동 수집 결과]
tool_call_total: {TOOL_TOTAL}
tool_breakdown : {TOOL_BREAKDOWN}
tokens         :
  input              : {input_tokens}
  output             : {output_tokens}
  cache_read         : {cache_read_input_tokens}
  cache_creation     : {cache_creation_input_tokens}

누적 저장 완료. 다음 단계:
  1. /clear → exit
  2. 새 세션 시작
  3. /harness-validate-clear task-start {task} {harness} {N+1}
```

### Step 5: 세션 파일 정리

```bash
rm docs/superpowers/validation/.session.json
rm -f /tmp/harness-validate-clear-slice.jsonl
```

---

## exec-done 명령 (마지막 Task)

### Step 1: 세션 파일 확인

`phase == "task"` 인지 확인. 아니면:
```
실행 중인 task 측정 세션이 없습니다. /harness-validate-clear task-start 를 먼저 실행하세요.
```

accumulator 파일도 함께 로드한다.

### Step 2: 현재 세션 transcript slice + 자동 수집

plan-done Step 3 와 동일 로직.

### Step 3: 전체 누적 집계

```bash
ACCUM="docs/superpowers/validation/.task-accumulator.json"

python3 - <<PY
import json

with open("$ACCUM") as f:
    acc = json.load(f)

# 현재 마지막 task 추가
acc["tasks"].append({
    "task_no": ${TASK_NO},
    "tool_call_total": ${TOOL_TOTAL},
    "tool_call_breakdown": ${TOOL_BREAKDOWN},
    "tokens": ${TOKENS}
})

# 전체 합산
total_tools = sum(t["tool_call_total"] for t in acc["tasks"])
total_tokens = {k: sum(t["tokens"].get(k, 0) for t in acc["tasks"])
                for k in ["input_tokens","output_tokens","cache_read_input_tokens","cache_creation_input_tokens"]}

breakdown_total = {}
for t in acc["tasks"]:
    for tool, cnt in t["tool_call_breakdown"].items():
        breakdown_total[tool] = breakdown_total.get(tool, 0) + cnt

print(json.dumps({
    "total_task_count": len(acc["tasks"]),
    "total_tool_call_total": total_tools,
    "total_tool_call_breakdown": breakdown_total,
    "total_tokens": total_tokens
}))
PY
```

### Step 4: 자동 수집 결과 표시 + rubric 출력

```
[자동 수집 결과 — 전체 합산 (Task 1~{TOTAL_TASKS})]
tool_call_total: {TOTAL_TOOL_TOTAL}
tool_breakdown : {TOTAL_TOOL_BREAKDOWN}
tokens         :
  input              : {total_input_tokens}
  output             : {total_output_tokens}
  cache_read         : {total_cache_read_input_tokens}
  cache_creation     : {total_cache_creation_input_tokens}
```

**T-A 채점 rubric:**
```
[채점 rubric — T-A exec ({TOTAL_TASKS} Task 전체)]
- buildable [y/n]: acceptance 4개 전체 통과
- hallucination_count [숫자]: {TOTAL_TASKS}개 task 세션 전체 합산
- correction_prompt_count [숫자]: {TOTAL_TASKS}개 task 세션 전체 합산
- repeated_mistake_count [숫자]: 동일 카테고리 실수 2회 이상 (세션 간 포함)
- task_context_loss_count [숫자]: /clear 후 이전 Task 결과 오인 / 재탐색 횟수
```

**T-B 채점 rubric:**
```
[채점 rubric — T-B exec ({TOTAL_TASKS} Task 전체)]
- buildable [y/n]: acceptance 4개 전체 통과
- bugs_fixed_count [0~3]: 실제로 수정된 버그 수 (코드 확인 기준)
- hallucination_count [숫자]: {TOTAL_TASKS}개 task 세션 전체 합산
- correction_prompt_count [숫자]: {TOTAL_TASKS}개 task 세션 전체 합산
- repeated_mistake_count [숫자]: 동일 카테고리 실수 2회 이상
- task_context_loss_count [숫자]: /clear 후 이전 버그 수정 상태 오인 횟수
```

### Step 5: 수동 질문 순차

**T-A:**
```
Q1. buildable [y/n]:
Q2. hallucination_count [숫자, {TOTAL_TASKS} task 합산]:
Q3. correction_prompt_count [숫자, {TOTAL_TASKS} task 합산]:
Q4. repeated_mistake_count [숫자]:
Q5. task_context_loss_count [숫자]:
```

**T-B:**
```
Q1. buildable [y/n]:
Q2. bugs_fixed_count [0~3]:
Q3. hallucination_count [숫자, {TOTAL_TASKS} task 합산]:
Q4. correction_prompt_count [숫자, {TOTAL_TASKS} task 합산]:
Q5. repeated_mistake_count [숫자]:
Q6. task_context_loss_count [숫자]:
```

### Step 6: 결과 저장

저장 경로:
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-clear-exec.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-clear-exec.md
```

**T-A .json 예시:**
```json
{
  "timestamp": "2026-05-15T00:00:00Z",
  "task_id": "T-A",
  "harness": "none",
  "workflow": "clear",
  "phase": "exec",
  "plan_file": "docs/superpowers/plans/T-A-none-clear-generated.md",
  "automated": {
    "tasks_included": [1, 2, 3, 4],
    "tool_call_total": 0,
    "tool_call_breakdown": { "Read": 0, "Edit": 0, "Bash": 0, "Write": 0 },
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0
  },
  "manual": {
    "buildable": true,
    "hallucination_count": 0,
    "correction_prompt_count": 0,
    "repeated_mistake_count": 0,
    "task_context_loss_count": 0
  }
}
```

**T-B .json 에는 `bugs_fixed_count` 추가.**

채점용 .md 는 본 문서 끝 **공통 transcript → markdown 변환 스크립트** 사용.

### Step 7: 세션 파일 정리 + 다음 trial 안내

```bash
rm docs/superpowers/validation/.session.json
rm -f docs/superpowers/validation/.task-accumulator.json
rm -f /tmp/harness-validate-clear-slice.jsonl
```

```
✓ exec 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-clear-exec.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-clear-exec.md

이 trial (task={task} / harness={harness} / workflow=clear) 완료.

다음 trial 준비:
  1. /clear → exit
  2. 새 세션 시작 (다음 harness worktree 또는 동일 worktree reset 후)
  3. /harness-validate-clear plan-start {다음 task} {harness}
```

---

## 공통: transcript → markdown 변환 스크립트

plan-done / task-done / exec-done 의 채점용 .md 생성에 사용한다.

```bash
python3 - <<'PY' > /tmp/harness-validate-clear.md
import json

TURN_LIMIT_ARG = 200
TURN_LIMIT_RES = 20

with open("/tmp/harness-validate-clear-slice.jsonl") as f:
    entries = [json.loads(line) for line in f if line.strip()]

with open("docs/superpowers/validation/.session.json") as f:
    sess = json.load(f)

label = f"{sess['task_id']} / {sess['harness']} / clear / {sess['phase']}"
if sess.get('task_no'):
    label += f" task={sess['task_no']}/{sess.get('total_tasks', '?')}"
print(f"# {label} — {sess['started_at']}\n")

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

mv /tmp/harness-validate-clear.md docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-clear-{phase}.md
```

---

## 운영 가이드

### Worktree 구성

take4 와 동일한 3 worktree 를 재사용한다.

| 브랜치 | harness 상태 | worktree 경로 |
|--------|-------------|--------------|
| `plugin_none` | root CLAUDE.md 만 | `.worktrees/plugin_none` |
| `plugin_root` | root CLAUDE.md + docs/*.md | `.worktrees/plugin_root` |
| `plugin_module` | root + docs + 모듈별 CLAUDE.md | `.worktrees/plugin_module` |

### 한 trial 의 전체 흐름

```
[plan 세션]
새 세션 시작 → /harness-validate-clear plan-start {task} {harness}
  → brainstorming 으로 Task 구조 결정
  → writing-plans 으로 plan 작성 (## Task N 헤더 포함)
  → plan 저장
  → /harness-validate-clear plan-done
  → 자동 수집 + rubric 4개 입력
  → /clear → exit

[exec 세션 — Task 1]
새 세션 시작 → /harness-validate-clear task-start {task} {harness} 1
  → 해당 Task 구현 (inline, subagent 금지)
  → /harness-validate-clear task-done
  → /clear → exit

... (Task 2 ~ N-1 반복)

[exec 세션 — 마지막 Task]
새 세션 시작 → /harness-validate-clear task-start {task} {harness} {N}
  → 해당 Task 구현 (inline) + acceptance 전체 검증
  → /harness-validate-clear exec-done
  → rubric 입력
  → /clear → exit → 다음 trial
```

### task_context_loss_count 채점 기준

`/clear` 이후 새 세션에서 이전 Task 결과를 잘못 인식하거나 이미 완료된 파일을 재탐색하는 경우를 1회로 센다. 단, task-start 가 출력한 `PREV_DONE` 안내를 읽고 정상적으로 맥락을 복원하는 경우는 카운트하지 않는다.

### take4 결과와 비교 시

- `workflow=clear` (이 스킬) vs `workflow=W-A` (take4 단일 세션) vs `workflow=W-B` (take4 subtask 분할)
- clear 는 brainstorming 이 항상 포함되므로 plan 품질 비교 시 W-A 대비 brainstorming 효과가 혼재됨에 유의
- `task_context_loss_count` 는 clear 고유 메트릭. take4 W-B 의 `subtask_context_loss_count` 와 정의 동일

### n=1 한계

각 (task × harness) 조합당 1회 측정. 큰 정성적 차이(plan 구조 / context loss 빈도)를 우선 판단 기준으로 삼는다.
