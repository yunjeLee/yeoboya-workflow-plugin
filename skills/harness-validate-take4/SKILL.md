---
name: harness-validate-take4
description: Take4 harness 효과 측정 세션을 시작·종료한다. T-A (feature_report 재구현 13개 파일) / T-B (SplashActivity 버그 3종 수정) 작업에 대해 W-A (단일 exec 세션) / W-B (brainstorming으로 subtask 자유 분해 후 분할 세션) 두 워크플로우로 plan + exec 전체 효과를 측정한다. /harness-validate-take4 plan-start {T-A|T-B} {none|root|module} {W-A|W-B} 로 시작.
model: opus
---

# Harness-Validate Take4

## 실험 구조

| 항목 | 값 |
|------|-----|
| Task T-A | feature_report 재구현 (13개 파일) |
| Task T-B | SplashActivity 버그 3종 수정 |
| Workflow W-A | plan + exec 단일 세션 |
| Workflow W-B | plan 1회 + subtask 별 분할 세션 (subtask 수는 LLM 이 brainstorming 으로 결정) |
| 측정 조건 | none / root / module |

### W-B subtask 구성

W-B 는 plan 작성 시 LLM 이 brainstorming 으로 subtask 수와 경계를 자유롭게 결정한다.
plan 의 `## Subtask N` 헤더가 세션 분할 기준이 된다.
마지막 subtask 는 `sub-done` 대신 `exec-done` 으로 전체 집계한다.

## 명령 체계

| 명령 | 용도 | 조건 |
|------|------|------|
| `plan-start {T-A\|T-B} {none\|root\|module} {W-A\|W-B}` | plan 측정 시작 | — |
| `plan-done` | plan 측정 종료 + 저장 | — |
| `exec-start {T-A\|T-B} {none\|root\|module} {W-A\|W-B}` | exec 단일 세션 시작 | W-A 전용 |
| `exec-done` | exec 전체 집계 종료 | W-A 단일 / W-B 마지막 subtask |
| `sub-start {T-A\|T-B} {none\|root\|module} {subtask번호}` | subtask 세션 시작 | W-B 전용 |
| `sub-done` | subtask 중간 종료 + 누적 | W-B 마지막 제외 |

---

## plan-start 명령

### Step 1: 인자 검증

- `task-id`: T-A / T-B
- `harness`: none / root / module
- `workflow`: W-A / W-B

오류 시 출력 후 종료:
```
사용법: /harness-validate-take4 plan-start {T-A|T-B} {none|root|module} {W-A|W-B}
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

`USER_MSG_COUNT > 1` 이면 경고 출력 후 종료:
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
  "workflow": "${WORKFLOW}",
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

`{harness}` 를 실제 값으로 치환해 아래 형식으로 출력한다.

**T-A W-A plan prompt** (`docs/superpowers/plans/T-A-{harness}-generated.md` 저장 지시 포함):

```
측정 시작 [T-A / harness={harness} / workflow=W-A / phase=plan]
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
1. superpowers:writing-plans 스킬을 사용한다.
2. 결과 plan 을 docs/superpowers/plans/T-A-{harness}-generated.md 에 저장한다.
3. 코드는 작성하지 않는다 — plan 작성까지만.

─────────────────────────────────────────
plan 작성 완료 → /harness-validate-take4 plan-done
```

**T-A W-B plan prompt** (절차 3·4가 subtask 단위로 다름):

```
측정 시작 [T-A / harness={harness} / workflow=W-B / phase=plan]
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
1. superpowers:brainstorming 스킬로 복구 작업을 분석하고 subtask 구조와 수를 결정한다.
2. superpowers:writing-plans 스킬로 plan 을 작성한다.
3. 결과 plan 을 docs/superpowers/plans/T-A-{harness}-generated.md 에 저장한다.
   (W-A 와 동일 파일명 — W-B 는 동일 plan 을 사용한다)
4. plan 의 각 subtask 는 반드시 "## Subtask N" 형식 헤더로 구분한다
   (sub-start 가 이 헤더를 기준으로 세션을 분할하기 때문).
5. 코드는 작성하지 않는다 — plan 작성까지만.

─────────────────────────────────────────
plan 작성 완료 → /harness-validate-take4 plan-done
```

**T-B plan prompt** (W-A / W-B 공통):

```
측정 시작 [T-B / harness={harness} / workflow={workflow} / phase=plan]
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
1. superpowers:brainstorming 스킬로 버그 수정 작업을 분석하고 subtask 구조와 수를 결정한다.
2. superpowers:writing-plans 스킬로 plan 을 작성한다.
3. 결과 plan 을 docs/superpowers/plans/T-B-{harness}-generated.md 에 저장한다.
4. plan 의 각 subtask 는 반드시 "## Subtask N" 형식 헤더로 구분한다
   (sub-start 가 이 헤더를 기준으로 세션을 분할하기 때문).
5. 코드는 작성하지 않는다 — plan 작성까지만.

─────────────────────────────────────────
plan 작성 완료 → /harness-validate-take4 plan-done
```

---

## plan-done 명령

### Step 1: 세션 파일 확인

```bash
SESSION_FILE="docs/superpowers/validation/.session.json"
```

파일 없거나 `phase != "plan"` 이면:
```
실행 중인 plan 측정 세션이 없습니다. 먼저 /harness-validate-take4 plan-start 를 실행하세요.
```

### Step 2: plan 파일 존재 확인

```bash
TASK_ID=$(jq -r '.task_id' "$SESSION_FILE")
HARNESS=$(jq -r '.harness' "$SESSION_FILE")
WORKFLOW=$(jq -r '.workflow' "$SESSION_FILE")
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"

if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  LLM 이 plan 작성을 완료한 후 다시 실행하세요."
  exit 1
fi
```

### Step 3: transcript slice + 자동 수집

```bash
TRANSCRIPT=$(jq -r '.transcript_path' "$SESSION_FILE")
LINE_START=$(jq -r '.line_start' "$SESSION_FILE")
LINE_END=$(wc -l < "$TRANSCRIPT")
SLICE=/tmp/harness-validate-take4-slice.jsonl

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
PLAN_TASK_COUNT=$(grep -cE '^#+\s+(Task|Subtask)\b' "$PLAN_FILE" || echo 0)
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

task별 rubric 안내:

**T-A 채점 rubric:**
```
[채점 rubric — T-A plan phase]
- plan_layer_structure_correct [y/n]
    data → feature 계층 순서 구성 여부 + (W-B: plan 에 ## Subtask N 헤더 존재 여부)
- plan_dependency_correct [y/n]
    DI 모듈, Hilt 바인딩, 의존성 방향이 plan 에 포함됐는지
- plan_acceptance_coverage [0~4]
    acceptance 4개 중 plan 이 명시적으로 다루는 개수
- plan_task_count [숫자]
    자동 추출값을 검토하고 필요 시 수정
```

**T-B 채점 rubric:**
```
[채점 rubric — T-B plan phase]
- plan_bug_diagnosis_correct [0~3]
    3개 버그 중 plan 이 원인을 올바르게 진단한 개수
- plan_fix_strategy_correct [0~3]
    3개 버그 중 plan 이 올바른 수정 방향을 제시한 개수
- plan_acceptance_coverage [0~4]
    acceptance 4개 중 plan 이 명시적으로 다루는 개수
- plan_task_count [숫자]
    자동 추출값을 검토하고 필요 시 수정
```

### Step 6: 수동 질문 순차 (task별)

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
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-{workflow}-plan.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-{workflow}-plan.md
```

**T-A .json 예시:**
```json
{
  "timestamp": "2026-05-14T00:00:00Z",
  "task_id": "T-A",
  "harness": "none",
  "workflow": "W-A",
  "phase": "plan",
  "plan_file": "docs/superpowers/plans/T-A-none-generated.md",
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
    "plan_task_count": 5
  }
}
```

**T-B .json 예시:**
```json
{
  "timestamp": "2026-05-14T00:00:00Z",
  "task_id": "T-B",
  "harness": "none",
  "workflow": "W-A",
  "phase": "plan",
  "plan_file": "docs/superpowers/plans/T-B-none-generated.md",
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
rm docs/superpowers/validation/.session.json /tmp/harness-validate-take4-slice.jsonl
```

**W-A 안내:**
```
✓ plan 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-W-A-plan.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-W-A-plan.md
  생성 plan: {PLAN_FILE}

다음 단계 (exec 세션 — W-A 단일):
  1. /clear → exit
  2. 새 세션 시작 (동일 worktree)
  3. /harness-validate-take4 exec-start {task} {harness} W-A
```

**W-B 안내:**
```
✓ plan 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-W-B-plan.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-W-B-plan.md
  생성 plan: {PLAN_FILE}

다음 단계 (W-B — subtask 1 세션):
  1. /clear → exit
  2. 새 세션 시작 (동일 worktree)
  3. /harness-validate-take4 sub-start {task} {harness} 1
```

---

## exec-start 명령 (W-A 전용)

### Step 1: 인자 검증

- `task-id`: T-A / T-B
- `harness`: none / root / module
- `workflow`: W-A 만 허용 (W-B는 sub-start 사용)

W-B 가 입력되면:
```
⚠ exec-start 는 W-A 전용입니다.
  W-B 는 /harness-validate-take4 sub-start {task} {harness} 1 로 시작하세요.
```

### Step 2: 신선한 세션 검증

plan-start Step 2 와 동일.

### Step 3: plan 파일 존재 확인

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  먼저 /harness-validate-take4 plan-start {task} {harness} {workflow} 를 완료하세요."
  exit 1
fi
```

### Step 4: 세션 파일 작성

```bash
mkdir -p docs/superpowers/validation
LINE_START=$(wc -l < "$LATEST_JSONL")

python3 - <<PY
import json
from datetime import datetime, timezone
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "workflow": "W-A",
  "phase": "exec",
  "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "transcript_path": "${LATEST_JSONL}",
  "line_start": ${LINE_START}
}
with open("docs/superpowers/validation/.session.json", "w") as f:
    json.dump(data, f, indent=2)
PY
```

### Step 5: exec prompt 출력

`{harness}` 치환 후 task별 exec prompt를 출력한다.

**T-A W-A exec prompt:**

```
측정 시작 [T-A / harness={harness} / workflow=W-A / phase=exec]
사용할 plan: docs/superpowers/plans/T-A-{harness}-generated.md
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

feature_report 기능을 복구하는 작업이다.

구현 plan 은 docs/superpowers/plans/T-A-{harness}-generated.md 에 이미 작성되어 있다.
이 plan 을 그대로 따라 구현한다.

절차 (반드시 지킬 것):
1. plan 파일을 끝까지 읽어 전체 task 흐름을 파악한다.
2. superpowers:executing-plans 스킬을 인라인으로 사용해 plan 의 Task 를 순서대로 실행한다
   (subagent 분산 실행 금지 — 현재 세션에서 직접 실행).
3. plan 의 Task 순서를 변경하거나 건너뛰지 않는다. plan 에 없는 추가 추상화 / 리팩토링도 하지 않는다.
4. 각 Task 의 체크리스트를 모두 완료한 뒤 다음 Task 로 넘어간다.

acceptance:
- ./gradlew :feature:feature_report:impl:compileDebugKotlin 통과
- ./gradlew :data:data_report:impl:compileDebugKotlin 통과
- ./gradlew :app:assembleDebug 통과
- ReportLauncher.show() 호출 시 ReportDialog 가 열린다

─────────────────────────────────────────
완료 → acceptance 검증 → /harness-validate-take4 exec-done
```

**T-B W-A exec prompt:**

```
측정 시작 [T-B / harness={harness} / workflow=W-A / phase=exec]
사용할 plan: docs/superpowers/plans/T-B-{harness}-generated.md
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

SplashActivity / SplashViewModel 버그 3개를 수정하는 작업이다.

구현 plan 은 docs/superpowers/plans/T-B-{harness}-generated.md 에 이미 작성되어 있다.
이 plan 을 그대로 따라 3개 버그를 모두 수정한다.

절차 (반드시 지킬 것):
1. plan 파일을 끝까지 읽어 전체 흐름을 파악한다.
2. superpowers:executing-plans 스킬을 인라인으로 사용해 순서대로 실행한다
   (subagent 분산 실행 금지 — 현재 세션에서 직접 실행).
3. Bug 1 → Bug 2 → Bug 3 순서를 바꾸지 않는다.
4. 각 버그 수정 후 해당 acceptance 를 바로 검증한다.

acceptance:
- Bug 1: SplashViewModel.downloadFile() 에서 DownloadManager.enqueue() 가 호출된다
- Bug 2: Firebase 실패 시에도 앱 초기화가 계속 진행된다 (onComplete 호출)
- Bug 3: getSplashDataUseCase 실패 시 splashDataState 가 Error 로 전환된다
- ./gradlew :feature:feature_splash:impl:compileDebugKotlin 통과

─────────────────────────────────────────
완료 → acceptance 검증 → /harness-validate-take4 exec-done
```

---

## exec-done 명령

W-A 단일 세션 종료 또는 W-B 마지막 subtask 종료 후 전체 집계에 사용한다.

### Step 1: 세션 파일 확인

`docs/superpowers/validation/.session.json` 의 `phase` 가 `"exec"` 또는 `"sub"` 이어야 한다.

없거나 다른 phase 이면:
```
실행 중인 exec/sub 측정 세션이 없습니다. exec-start 또는 마지막 sub-start 를 먼저 실행하세요.
```

W-B(`workflow == "W-B"`) 인 경우: `.subtask-accumulator.json` 도 함께 로드한다.

### Step 2: 현재 세션 transcript slice + 자동 수집

plan-done Step 3 와 동일 로직. 결과를 `SLICE=/tmp/harness-validate-take4-slice.jsonl` 에 저장.

### Step 3: W-B 누적 집계

`workflow == "W-B"` 이면 accumulator 의 이전 subtask 메트릭과 현재 세션 메트릭을 합산한다.

```bash
ACCUM="docs/superpowers/validation/.subtask-accumulator.json"

python3 - <<PY
import json

with open("$ACCUM") as f:
    acc = json.load(f)

# 현재 세션 메트릭 (TOOL_TOTAL, TOOL_BREAKDOWN, TOKENS 변수에서 로드)
current = {
    "subtask_no": acc["next_subtask"],
    "tool_call_total": ${TOOL_TOTAL},
    "tool_call_breakdown": ${TOOL_BREAKDOWN},
    "tokens": ${TOKENS}
}
acc["subtasks"].append(current)

# 전체 합산
total_tools = sum(s["tool_call_total"] for s in acc["subtasks"])
total_tokens = {k: sum(s["tokens"].get(k, 0) for s in acc["subtasks"])
                for k in ["input_tokens","output_tokens","cache_read_input_tokens","cache_creation_input_tokens"]}

breakdown_total = {}
for s in acc["subtasks"]:
    for tool, cnt in s["tool_call_breakdown"].items():
        breakdown_total[tool] = breakdown_total.get(tool, 0) + cnt

print(json.dumps({
    "total_tool_call_total": total_tools,
    "total_tool_call_breakdown": breakdown_total,
    "total_tokens": total_tokens
}))
PY
```

### Step 4: 자동 수집 결과 표시 + rubric 출력

W-A:
```
[자동 수집 결과 — W-A 단일 세션]
tool_call_total: {TOOL_TOTAL}
tool_breakdown : {TOOL_BREAKDOWN}
tokens         :
  input              : {input_tokens}
  output             : {output_tokens}
  cache_read         : {cache_read_input_tokens}
  cache_creation     : {cache_creation_input_tokens}
```

W-B:
```
[자동 수집 결과 — W-B 전체 합산 (subtask 1~{N})]
tool_call_total: {TOTAL_TOOL_TOTAL}
tool_breakdown : {TOTAL_TOOL_BREAKDOWN}
tokens         :
  input              : {total_input_tokens}
  output             : {total_output_tokens}
  cache_read         : {total_cache_read_input_tokens}
  cache_creation     : {total_cache_creation_input_tokens}
```

task + workflow별 rubric 안내:

**T-A W-A exec rubric:**
```
[채점 rubric — T-A exec / W-A]
- buildable [y/n]: acceptance 4개 전체 통과
- hallucination_count [숫자]: 존재하지 않는 API / import / 파일 참조 횟수
- correction_prompt_count [숫자]: 보정 의도 메시지 수 (단순 후속 질문 제외)
- repeated_mistake_count [숫자]: 동일 카테고리 실수 2회 이상 지적 횟수
```

**T-A W-B exec rubric (전체 집계):**
```
[채점 rubric — T-A exec / W-B ({TOTAL_SUBTASKS} subtask 전체)]
- buildable [y/n]: acceptance 4개 전체 통과
- hallucination_count [숫자]: {TOTAL_SUBTASKS}개 subtask 세션 전체 합산
- correction_prompt_count [숫자]: {TOTAL_SUBTASKS}개 subtask 세션 전체 합산
- repeated_mistake_count [숫자]: 동일 카테고리 실수 2회 이상 (세션 간 포함)
- subtask_context_loss_count [숫자]: /clear 후 이전 subtask 결과 오인 / 재탐색 횟수
```

**T-B W-A exec rubric:**
```
[채점 rubric — T-B exec / W-A]
- buildable [y/n]: acceptance 4개 전체 통과
- bugs_fixed_count [0~3]: 실제로 수정된 버그 수 (코드 확인 기준)
- hallucination_count [숫자]: 존재하지 않는 API / 함수 참조 횟수
- correction_prompt_count [숫자]: 보정 의도 메시지 수
- repeated_mistake_count [숫자]: 동일 카테고리 실수 2회 이상 지적 횟수
```

**T-B W-B exec rubric (전체 집계):**
```
[채점 rubric — T-B exec / W-B ({TOTAL_SUBTASKS} subtask 전체)]
- buildable [y/n]: acceptance 4개 전체 통과
- bugs_fixed_count [0~3]: 실제로 수정된 버그 수
- hallucination_count [숫자]: {TOTAL_SUBTASKS}개 subtask 세션 전체 합산
- correction_prompt_count [숫자]: {TOTAL_SUBTASKS}개 subtask 세션 전체 합산
- repeated_mistake_count [숫자]: 동일 카테고리 실수 2회 이상
- subtask_context_loss_count [숫자]: /clear 후 이전 버그 수정 상태 오인 횟수
```

### Step 5: 수동 질문 순차 (task + workflow별)

**T-A W-A:**
```
Q1. buildable [y/n]:
Q2. hallucination_count [숫자]:
Q3. correction_prompt_count [숫자]:
Q4. repeated_mistake_count [숫자]:
```

**T-A W-B:**
```
Q1. buildable [y/n]:
Q2. hallucination_count [숫자, {TOTAL_SUBTASKS} subtask 합산]:
Q3. correction_prompt_count [숫자, {TOTAL_SUBTASKS} subtask 합산]:
Q4. repeated_mistake_count [숫자]:
Q5. subtask_context_loss_count [숫자]:
```

**T-B W-A:**
```
Q1. buildable [y/n]:
Q2. bugs_fixed_count [0~3]:
Q3. hallucination_count [숫자]:
Q4. correction_prompt_count [숫자]:
Q5. repeated_mistake_count [숫자]:
```

**T-B W-B:**
```
Q1. buildable [y/n]:
Q2. bugs_fixed_count [0~3]:
Q3. hallucination_count [숫자, {TOTAL_SUBTASKS} subtask 합산]:
Q4. correction_prompt_count [숫자, {TOTAL_SUBTASKS} subtask 합산]:
Q5. repeated_mistake_count [숫자]:
Q6. subtask_context_loss_count [숫자]:
```

### Step 6: 결과 저장

저장 경로:
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-{workflow}-exec.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-{workflow}-exec.md
```

**T-A W-A .json 예시:**
```json
{
  "timestamp": "2026-05-14T00:00:00Z",
  "task_id": "T-A",
  "harness": "none",
  "workflow": "W-A",
  "phase": "exec",
  "plan_file": "docs/superpowers/plans/T-A-none-generated.md",
  "automated": {
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
    "repeated_mistake_count": 0
  }
}
```

**T-A W-B .json 예시:**
```json
{
  "timestamp": "2026-05-14T00:00:00Z",
  "task_id": "T-A",
  "harness": "none",
  "workflow": "W-B",
  "phase": "exec",
  "plan_file": "docs/superpowers/plans/T-A-none-generated.md",
  "automated": {
    "subtasks_included": [1, 2, 3, 4],
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
    "subtask_context_loss_count": 0
  }
}
```

**T-B W-B .json 에는 `bugs_fixed_count` 추가.**

채점용 .md 는 본 문서 끝 **공통 transcript → markdown 변환 스크립트** 사용.

### Step 7: 세션 파일 정리 + 다음 trial 안내

```bash
rm docs/superpowers/validation/.session.json
rm -f docs/superpowers/validation/.subtask-accumulator.json
rm -f /tmp/harness-validate-take4-slice.jsonl
```

```
✓ exec 측정 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}-{workflow}-exec.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}-{workflow}-exec.md

이 trial (task={task} / harness={harness} / workflow={workflow}) 완료.

다음 trial 준비:
  1. /clear → exit
  2. 새 세션 시작 (다음 harness worktree 또는 동일 worktree reset 후)
  3. /harness-validate-take4 plan-start {다음 task} {harness} {workflow}
```

---

## sub-start 명령 (W-B 전용)

### Step 1: 인자 검증

- `task-id`: T-A / T-B
- `harness`: none / root / module
- `subtask_no`: 1 ~ (plan 의 ## Subtask N 헤더 수)

오류 시:
```
사용법: /harness-validate-take4 sub-start {T-A|T-B} {none|root|module} {subtask번호}
```

### Step 2: 신선한 세션 검증

plan-start Step 2 와 동일.

### Step 3: plan 파일 존재 확인

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "⚠ plan 파일이 없습니다: $PLAN_FILE"
  echo "  먼저 /harness-validate-take4 plan-start {task} {harness} W-B 를 완료하세요."
  exit 1
fi
```

### Step 4: accumulator 초기화 (subtask 1일 때만)

```bash
ACCUM="docs/superpowers/validation/.subtask-accumulator.json"

if [ "${SUBTASK_NO}" = "1" ]; then
  python3 - <<PY
import json
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "workflow": "W-B",
  "next_subtask": 1,
  "subtasks": []
}
with open("$ACCUM", "w") as f:
    json.dump(data, f, indent=2)
PY
else
  # accumulator 가 없으면 오류
  if [ ! -f "$ACCUM" ]; then
    echo "⚠ subtask accumulator 가 없습니다. subtask 1 부터 시작하세요."
    exit 1
  fi
fi
```

### Step 5: 세션 파일 작성

```bash
LINE_START=$(wc -l < "$LATEST_JSONL")

python3 - <<PY
import json
from datetime import datetime, timezone
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "workflow": "W-B",
  "phase": "sub",
  "subtask_no": ${SUBTASK_NO},
  "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "transcript_path": "${LATEST_JSONL}",
  "line_start": ${LINE_START}
}
with open("docs/superpowers/validation/.session.json", "w") as f:
    json.dump(data, f, indent=2)
PY
```

### Step 6: subtask prompt 동적 출력

plan 파일을 읽어 총 subtask 수와 해당 섹션 내용을 추출한 뒤 prompt 를 생성한다.

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"

# 총 subtask 수 카운트
TOTAL_SUBTASKS=$(grep -cE '^## Subtask [0-9]+' "$PLAN_FILE")

# 마지막 subtask 여부
IS_LAST=$( [ "$SUBTASK_NO" = "$TOTAL_SUBTASKS" ] && echo "true" || echo "false" )

# plan 에서 Subtask N 섹션 추출 (다음 ## Subtask 헤더 또는 파일 끝까지)
NEXT=$((SUBTASK_NO + 1))
SUBTASK_CONTENT=$(awk \
  "/^## Subtask ${SUBTASK_NO}$/{found=1; next} \
   found && /^## Subtask [0-9]+/{exit} \
   found{print}" "$PLAN_FILE" | head -80)

# 이전 subtask 완료 문구 생성 (N>=2 일 때)
if [ "$SUBTASK_NO" -ge 2 ]; then
  PREV_DONE="Subtask 1 ~ $((SUBTASK_NO - 1)) 은 이미 완료된 상태다."
else
  PREV_DONE=""
fi
```

출력 형식 (`{변수}` 는 위 값으로 치환):

```
측정 시작 [{TASK_ID} / harness={HARNESS} / workflow=W-B / subtask={SUBTASK_NO}/{TOTAL_SUBTASKS}]
사용할 plan: {PLAN_FILE}
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

{TASK_ID} 작업 중 Subtask {SUBTASK_NO} / {TOTAL_SUBTASKS} 을 진행한다.
{PREV_DONE}

plan 파일: {PLAN_FILE}
이번 세션에서 구현할 범위: plan 의 아래 ## Subtask {SUBTASK_NO} 섹션을 따른다.

--- plan Subtask {SUBTASK_NO} 시작 ---
{SUBTASK_CONTENT}
--- plan Subtask {SUBTASK_NO} 끝 ---

절차:
1. 위 plan 섹션 전체를 숙지한다.
2. superpowers:executing-plans 스킬을 인라인으로 사용해 실행한다
   (subagent 분산 실행 금지 — 현재 세션에서 직접 실행).
3. Subtask {SUBTASK_NO} 완료 후 세션을 종료한다.
[IS_LAST=true 일 때만 추가]
4. 완료 후 아래 acceptance 를 전체 검증한다:
   [task 별 acceptance 목록 삽입 — T-A 또는 T-B]

─────────────────────────────────────────
[IS_LAST=false] 완료 → /harness-validate-take4 sub-done
[IS_LAST=true]  ⚠ 마지막 subtask — 완료 후 exec-done 으로 전체 집계
                완료 → acceptance 검증 → /harness-validate-take4 exec-done
```

**task 별 acceptance 목록 (IS_LAST=true 일 때 삽입):**

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

## sub-done 명령 (W-B 중간 subtask)

### Step 1: 세션 파일 확인

`phase == "sub"` 인지 확인. 아니면:
```
실행 중인 sub 측정 세션이 없습니다. /harness-validate-take4 sub-start 를 먼저 실행하세요.
```

마지막 subtask 여부를 plan 파일에서 동적으로 판단:

```bash
PLAN_FILE="docs/superpowers/plans/${TASK_ID}-${HARNESS}-generated.md"
TOTAL_SUBTASKS=$(grep -cE '^## Subtask [0-9]+' "$PLAN_FILE")
SUBTASK_NO=$(jq -r '.subtask_no' docs/superpowers/validation/.session.json)

if [ "$SUBTASK_NO" = "$TOTAL_SUBTASKS" ]; then
  echo "⚠ 이 subtask 는 마지막 subtask 입니다 (${SUBTASK_NO}/${TOTAL_SUBTASKS})."
  echo "  sub-done 대신 /harness-validate-take4 exec-done 으로 전체 집계하세요."
  exit 1
fi
```

### Step 2: transcript slice + 자동 수집

exec-done Step 2 와 동일 로직.

### Step 3: accumulator 에 현재 subtask 메트릭 추가

```bash
ACCUM="docs/superpowers/validation/.subtask-accumulator.json"
SUBTASK_NO=$(jq -r '.subtask_no' docs/superpowers/validation/.session.json)

python3 - <<PY
import json

with open("$ACCUM") as f:
    acc = json.load(f)

acc["subtasks"].append({
    "subtask_no": ${SUBTASK_NO},
    "tool_call_total": ${TOOL_TOTAL},
    "tool_call_breakdown": ${TOOL_BREAKDOWN},
    "tokens": ${TOKENS}
})
acc["next_subtask"] = ${SUBTASK_NO} + 1

with open("$ACCUM", "w") as f:
    json.dump(acc, f, indent=2)
PY
```

### Step 4: 자동 수집 결과 표시

```
[Subtask {N} 자동 수집 결과]
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
  3. /harness-validate-take4 sub-start {task} {harness} {N+1}
```

### Step 5: 세션 파일 정리

```bash
rm docs/superpowers/validation/.session.json
rm -f /tmp/harness-validate-take4-slice.jsonl
```

---

## 공통: transcript → markdown 변환 스크립트

plan-done / exec-done / sub-done 의 채점용 .md 생성에 사용한다.

```bash
python3 - <<'PY' > /tmp/harness-validate-take4.md
import json

TURN_LIMIT_ARG = 200
TURN_LIMIT_RES = 20

with open("/tmp/harness-validate-take4-slice.jsonl") as f:
    entries = [json.loads(line) for line in f if line.strip()]

with open("docs/superpowers/validation/.session.json") as f:
    sess = json.load(f)

label = f"{sess['task_id']} / {sess['harness']} / {sess['workflow']} / {sess['phase']}"
if sess.get('subtask_no'):
    label += f" subtask={sess['subtask_no']}"
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

mv /tmp/harness-validate-take4.md docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}-{workflow}-{phase}.md
```

---

## 운영 가이드

### Worktree 구성

| 브랜치 | harness 상태 | worktree 경로 |
|--------|-------------|--------------|
| `plugin_none` | root CLAUDE.md 만 | `.worktrees/plugin_none` |
| `plugin_root` | root CLAUDE.md + docs/*.md | `.worktrees/plugin_root` |
| `plugin_module` | root + docs + 모듈별 CLAUDE.md | `.worktrees/plugin_module` |

### T-A 사전 조건 확인

실험 시작 전 삭제 대상 파일이 없어야 한다 (T-A-deletion.md 참조):
```bash
# 아래 파일들이 존재하면 아직 삭제되지 않은 상태
ls {worktree}/feature/feature_report/impl/src/main/java/kr/co/inforexseoul/feature_report_impl/ReportDialog.kt 2>/dev/null \
  && echo "⚠ 삭제 필요" || echo "✓ 삭제 완료"
```

### T-B 사전 조건 확인

실험 시작 전 3개 버그가 모두 심어진 상태여야 한다 (T-B-bugs.md 참조):
```bash
# Bug 2 확인: addOnFailureListener 가 없어야 함
grep -n "addOnFailureListener" {worktree}/feature/feature_splash/impl/src/main/java/kr/co/inforexseoul/feature_splash_impl/SplashActivity.kt \
  && echo "⚠ Bug 2 미심어짐" || echo "✓ Bug 2 확인"
```

### Trial 초기화

```bash
# T-A: 각 trial 시작 전 삭제 상태로 reset
git -C "$WORKTREE" reset --hard HEAD  # 삭제 commit 이 HEAD 인 경우

# T-B: 각 trial 시작 전 버그 상태로 reset
git -C "$WORKTREE" reset --hard HEAD  # 버그 baseline commit 이 HEAD 인 경우
```

### 결과 수합

```bash
DALLA=/Users/iyunje/AndroidStudio/dalla
RESULTS="$DALLA-take4-results"
mkdir -p "$RESULTS"
for wt in plugin_none plugin_root plugin_module; do
  cp "$DALLA/.worktrees/$wt/docs/superpowers/validation/"*.{json,md} "$RESULTS/" 2>/dev/null
  cp "$DALLA/.worktrees/$wt/docs/superpowers/plans/"*-generated.md   "$RESULTS/" 2>/dev/null
done
```

### n=1 한계

각 (task × harness × workflow) 조합당 1회 측정이므로 LLM 분산과 harness 효과를 통계적으로 분리할 수 없다. 큰 정성적 차이(plan 구조 / acceptance 누락 / W-B context_loss 빈도)를 우선 판단 기준으로 삼는다.
