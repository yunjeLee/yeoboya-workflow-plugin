---
name: harness-validate
description: harness 효과 측정 세션을 시작·종료한다. /harness-validate start {T1|T2} {none|root|module} 로 시작, /harness-validate done 으로 종료. transcript 자동 파싱으로 tool_call·token 수집, rubric 기반 4 개 수동 항목 입력 후 JSON + 채점용 markdown 저장. 한 세션 = 한 trial 원칙. dalla 모듈 분리 작업 (Phase 1-4 profile, Phase 1-5 report) 측정용.
model: opus
---

# Harness-Validate Skill — harness 효과 측정 (n=1)

총 6 trial = 2 task (T1 profile / T2 report) × 3 harness (none / root / module).
3 터미널 병렬 운영. **한 세션 = 한 trial.** trial 종료 후 `/clear` → `exit` → 새 세션.

## 트리거

- `/harness-validate start {task-id} {harness}` — 측정 시작
- `/harness-validate done` — 측정 종료 + 자동 수집 + 수동 입력 + 저장

### harness 정의

| harness | 적용 파일 |
|---------|----------|
| `none`   | root `CLAUDE.md` 만 |
| `root`   | root `CLAUDE.md` + `docs/*.md` |
| `module` | root `CLAUDE.md` + `docs/*.md` + 모듈별 `CLAUDE.md` |

### task 정의

| task | 작업 | 매핑 plan |
|------|------|----------|
| T1 | profile 기능을 `:feature:feature_profile:{api,impl}` + `:data:data_profile:{api,impl}` 로 분리 | `docs/superpowers/plans/2026-04-29-phase-1-4-profile.md` |
| T2 | report 기능을 `:feature:feature_report:{api,impl}` + `:data:data_report:{api,impl}` 로 분리 | `docs/superpowers/plans/2026-04-29-phase-1-5-report.md` |

> 측정 시 prompt 는 acceptance 만 알려주는 P-3 방식. plan 파일은 **참조하지 말 것** 으로 명시한다 (LLM 이 plan 을 그대로 따라 하면 harness 효과가 plan 디테일에 흡수됨).

## 측정 항목

### 자동 (transcript 파싱)
- `tool_call_total` + `tool_call_breakdown` (Read / Edit / Bash / Grep / Write 등)
- `input_tokens` / `output_tokens` / `cache_read_input_tokens` / `cache_creation_input_tokens`

### 수동 (rubric 기반)
- `buildable` [y/n]: 빌드 통과 + acceptance 만족
- `hallucination_count`: 존재하지 않는 API / import / 함수 / 파일경로 등장 횟수
- `correction_prompt_count`: "다시 / 틀렸어 / 수정해줘" 류 보정 의도 메시지 수 (단순 후속 질문 제외)
- `repeated_mistake_count`: 한 trial 내 동일 카테고리 실수를 2 회 이상 지적해야 한 횟수

---

## start 명령

### Step 1: 인자 검증

- `task-id`: T1 / T2
- `harness`: none / root / module

오류 시 출력 후 종료:
```
사용법: /harness-validate start {T1|T2} {none|root|module}
```

### Step 2: 신선한 세션 검증 (안전장치)

활성 transcript 의 user 메시지 수가 1 (= 현재 start 명령 자체) 을 초과하면 경고 후 종료한다.

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

### Step 3: targets.json 확인 + prompt 로드

`docs/superpowers/validation/targets.json` 이 없으면 템플릿을 생성하고 종료:

```json
{
  "T1": "profile 기능을 새 모듈로 분리해줘.\n\n절차 (반드시 지킬 것):\n1. superpowers:brainstorming 스킬을 사용해 구현 계획을 세운다.\n2. brainstorming 결과를 markdown 으로 정리해 plans/{YYYY-MM-DD}-validate-T1-profile.md 에 저장한다.\n   - 분리 대상 파일 목록, 신규 모듈 구조, 패키지 이동 경로, gradle 의존성 변경, 단계별 작업 순서 포함.\n3. 작성한 plan 경로를 보여주고 \"이 계획대로 진행할까요?\" 라고 사용자 확인을 받는다.\n4. 사용자가 승인하면 그때부터 코드 변경을 시작한다.\n\nacceptance:\n- :feature:feature_profile:{api,impl}, :data:data_profile:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.profile 패키지 비어 있음\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.profile\" app/src/main/java/ 결과 0 건\n\n표준 절차는 docs/ 참고.",

  "T2": "report 기능을 새 모듈로 분리해줘.\n\n절차 (반드시 지킬 것):\n1. superpowers:brainstorming 스킬을 사용해 구현 계획을 세운다.\n2. brainstorming 결과를 markdown 으로 정리해 plans/{YYYY-MM-DD}-validate-T2-report.md 에 저장한다.\n   - 분리 대상 파일 목록, 신규 모듈 구조, 패키지 이동 경로, gradle 의존성 변경, 단계별 작업 순서 포함.\n3. 작성한 plan 경로를 보여주고 \"이 계획대로 진행할까요?\" 라고 사용자 확인을 받는다.\n4. 사용자가 승인하면 그때부터 코드 변경을 시작한다.\n\nacceptance:\n- :feature:feature_report:{api,impl}, :data:data_report:{api,impl} 4 모듈 생성\n- kr.co.inforexseoul.radioproject.ui.report 패키지 비어 있음\n- 외부 노출 상수 (ReportType, ReportFrom) 는 :feature:feature_report:api 로 이동\n- ./gradlew :app:assembleDebug 통과\n- grep -rn \"radioproject.ui.report\" app/src/main/java/ 결과 0 건\n\n표준 절차는 docs/ 참고."
}
```

```
✓ targets.json 템플릿을 생성했습니다.
  내용을 확인한 후 다시 실행하세요.
  경로: docs/superpowers/validation/targets.json
```

있으면 해당 task 의 prompt 를 로드한다.

### Step 4: 세션 파일 작성

```bash
mkdir -p docs/superpowers/validation
LINE_START=$(wc -l < "$LATEST_JSONL")
python3 - <<PY
import json, time
from datetime import datetime, timezone
data = {
  "task_id": "${TASK_ID}",
  "harness": "${HARNESS}",
  "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "transcript_path": "${LATEST_JSONL}",
  "line_start": ${LINE_START}
}
with open("docs/superpowers/validation/.session.json", "w") as f:
    json.dump(data, f, indent=2)
PY
```

### Step 5: 측정 시작 안내 + prompt 출력

```
측정 시작 [{task-id} / harness={harness}]
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

  {targets.json 의 해당 prompt}

─────────────────────────────────────────
완료 → acceptance 검증 → /harness-validate done
```

---

## done 명령

### Step 1: 세션 파일 확인

`docs/superpowers/validation/.session.json` 이 없으면:
```
실행 중인 측정 세션이 없습니다. 먼저 /harness-validate start 를 실행하세요.
```

### Step 2: transcript slice 추출 + 자동 수집

`.session.json` 의 `transcript_path` / `line_start` 사용. line_start 이후 ~ 현재까지 잘라낸다.

```bash
SESSION_FILE=docs/superpowers/validation/.session.json
TRANSCRIPT=$(jq -r '.transcript_path' $SESSION_FILE)
LINE_START=$(jq -r '.line_start' $SESSION_FILE)
LINE_END=$(wc -l < "$TRANSCRIPT")
SLICE=/tmp/harness-validate-slice.jsonl

sed -n "$((LINE_START + 1)),${LINE_END}p" "$TRANSCRIPT" > "$SLICE"

# tool_use 집계
TOOL_TOTAL=$(jq -s '
  [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length
' "$SLICE")

TOOL_BREAKDOWN=$(jq -s -c '
  [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name]
  | group_by(.) | map({key: .[0], value: length}) | from_entries
' "$SLICE")

# 토큰 합산
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

### Step 3: 자동 수집 결과 표시

수집 결과를 사용자에게 그대로 보여주고 다음 단계로 넘어간다.

```
[자동 수집 결과]
tool_call_total: {TOOL_TOTAL}
tool_breakdown : {TOOL_BREAKDOWN}
tokens         :
  input              : {input_tokens}
  output             : {output_tokens}
  cache_read         : {cache_read_input_tokens}
  cache_creation     : {cache_creation_input_tokens}
```

### Step 4: rubric 출력 + 4 개 수동 질문 순차

먼저 rubric 을 출력해 채점 기준을 환기시킨다.

```
[채점 rubric]
- buildable: 빌드 통과 + 요청한 acceptance 만족 시 y
- hallucination: 존재하지 않는 API / import / 함수 / 파일경로 등장 횟수
- correction_prompt: "다시 / 틀렸어 / 수정해줘" 류 보정 의도 메시지 수
                    (단순 후속 질문 제외)
- repeated_mistake: 한 trial 내 동일 카테고리 실수를 2 회 이상 지적해야 한 횟수
```

질문은 한 번에 하나씩 묻고 응답을 받는다.

```
Q1. buildable [y/n]:
Q2. hallucination_count [숫자]:
Q3. correction_prompt_count [숫자]:
Q4. repeated_mistake_count [숫자]:
```

### Step 5: 결과 저장 (.json + .md)

저장 경로 (둘 다 동일 prefix):
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}.json
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}.md
```

#### 5-1. .json 파일 (메트릭)

스키마:
```json
{
  "timestamp": "2026-05-08T14:32:00Z",
  "task_id": "T1",
  "harness": "none",
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

Write tool 로 직접 저장한다.

#### 5-2. .md 파일 (채점용 transcript markdown)

`/tmp/harness-validate-slice.jsonl` 을 사람이 읽기 좋은 markdown 으로 변환한다.

변환 규칙:
- 각 jsonl entry 를 `## Turn {N} (user|assistant)` 단위로 끊는다.
- assistant turn 안에 `tool_use` 가 여러 개면 `### Tool: {name}` 로 모두 표시.
- tool_use 의 `input` 에서 핵심 인자만 보여준다 (예: Bash → `command`, Read/Edit → `file_path`, Grep → `pattern`).
- 각 인자값이 200 자를 넘으면 첫 200 자 + ` (... 생략 N 자)` 표기.
- tool_result 는 첫 20 줄까지만 보여주고 그 이상이면 `(... 생략 N 줄)` 표기.

변환 처리는 다음 흐름으로 진행한다:

```bash
python3 - <<'PY' > /tmp/harness-validate.md
import json, sys

TURN_LIMIT_ARG = 200
TURN_LIMIT_RES = 20  # lines

with open("/tmp/harness-validate-slice.jsonl") as f:
    entries = [json.loads(line) for line in f if line.strip()]

with open("docs/superpowers/validation/.session.json") as f:
    sess = json.load(f)

print(f"# {sess['task_id']} / {sess['harness']} — {sess['started_at']}\n")

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

mv /tmp/harness-validate.md docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}.md
```

> 변환 스크립트는 transcript jsonl 의 정확한 구조에 따라 미세 조정이 필요할 수 있다. 첫 trial 에서 한 번 결과 .md 를 직접 열어 가독성을 확인하고, 필요 시 변환 규칙을 다듬는다.

### Step 6: 세션 파일 정리 + 다음 trial 안내

```bash
rm docs/superpowers/validation/.session.json /tmp/harness-validate-slice.jsonl
```

```
✓ 저장 완료
  메트릭   : docs/superpowers/validation/{ts}-{task}-{harness}.json
  채점용 md: docs/superpowers/validation/{ts}-{task}-{harness}.md

다음 trial 준비:
  1. /clear
  2. exit
  3. 새 세션 시작
  4. /harness-validate start {다음 task} {harness}

채점 안내:
  6 trial 이 모두 끝난 뒤 .md 파일을 열어 Q1~Q4 를 채점하세요.
  현재 .json 의 manual 항목은 이번 done 시 입력한 값입니다 —
  채점 결과가 다르면 직접 수정해 정합성을 맞춥니다.
```

---

## 운영 가이드 (측정자용)

### 브랜치 / Worktree 구성

dalla 프로젝트에 미리 만든 3 브랜치를 worktree 로 펼친다. 각 브랜치는 측정 시작 전에 의도된 harness 상태로 commit 되어 있어야 한다.

| 브랜치 | harness 상태 | worktree 디렉토리 |
|--------|-------------|------------------|
| `migration_v2_2_none`   | root `CLAUDE.md` 만 (docs/ + 모듈 CLAUDE.md 삭제 commit) | `dalla-none/` |
| `migration_v2_2_root`   | root `CLAUDE.md` + `docs/*.md` (모듈 CLAUDE.md 삭제 commit) | `dalla-root/` |
| `migration_v2_2_module` | + 모듈별 `CLAUDE.md` (전부 유지) | `dalla-module/` |

```bash
cd /Users/iyunje/AndroidStudio/dalla
git worktree add ../dalla-none   migration_v2_2_none
git worktree add ../dalla-root   migration_v2_2_root
git worktree add ../dalla-module migration_v2_2_module
```

각 터미널이 각 worktree 디렉토리에서 독립 세션으로 측정한다.
측정 종료 후 정리:

```bash
git worktree remove ../dalla-none
git worktree remove ../dalla-root
git worktree remove ../dalla-module
```

### 한 trial 의 흐름

```
새 세션 시작 (해당 worktree 디렉토리)
  → /harness-validate start {task} {harness}
  → targets.json 의 prompt 를 그대로 입력
  → 작업 진행 (필요 시 보정 prompt 추가)
  → acceptance 검증 (빌드 / 동작 확인)
  → /harness-validate done
  → 자동 수집 표시 + Q1~Q4 입력
  → /clear → exit → 새 세션
```

### task 단위 동기화 권장

T1 (profile) 을 세 worktree 모두 끝낸 뒤 T2 (report) 시작. 즉 (task × harness) 가 아닌 task 단위로 다 같이 진행. 캐시 / 채점 일관성 확보 목적.

### 채점 운영

- 채점은 6 trial 이 모두 끝난 뒤 `.md` 파일들을 차례로 열어 일괄 진행
- 가능하면 파일명에서 harness 부분을 일시적으로 가리고 채점 (간이 blinding)
- correction_prompt / repeated_mistake 의 카테고리 분류는 6 trial 동안 일관 기준 유지
- done 시 입력한 manual 값과 일괄 채점 결과가 다르면 .json 의 manual 항목을 수정

### 결과 수합

각 worktree 에 흩어진 결과를 한 곳에 모아 분석:

```bash
mkdir -p /Users/iyunje/AndroidStudio/dalla-validation-results
cp ../dalla-none/docs/superpowers/validation/*.{json,md}   /Users/iyunje/AndroidStudio/dalla-validation-results/ 2>/dev/null
cp ../dalla-root/docs/superpowers/validation/*.{json,md}   /Users/iyunje/AndroidStudio/dalla-validation-results/ 2>/dev/null
cp ../dalla-module/docs/superpowers/validation/*.{json,md} /Users/iyunje/AndroidStudio/dalla-validation-results/ 2>/dev/null
```

### n=1 한계

각 (task × harness) 조합당 1 회 측정이라 LLM 분산과 harness 효과를 통계적으로 분리할 수 없다.
큰 차이 (예: 도구 호출 50% 이상 감소, 같은 실수 반복 0 vs 5) 만 directional 결론 대상이며, 작은 차이 (5~10% 토큰 차) 는 분산 가능성을 배제할 수 없다.
