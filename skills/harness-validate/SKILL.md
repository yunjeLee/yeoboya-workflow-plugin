---
name: harness-validate
description: "harness 효과 측정 세션을 시작·종료한다. /harness-validate start {task} {harness} 로 측정 시작, /harness-validate done 으로 종료 후 메트릭 수집 + JSON 저장. dalla 마이그레이션 작업 기반 T1~T4 측정 시 사용한다."
model: opus
---

# Harness-Validate Skill — harness 효과 측정

harness 조건(off / root / module)별로 동일 task 를 수행하고 결과 메트릭을 수집한다. 모든 측정은 input prompt → Claude 가 plan 수립 → phase 실행 흐름으로 진행한다.

## 트리거

- `/harness-validate start {task-id} {harness}` — 측정 세션 시작
- `/harness-validate done` — 측정 세션 종료 + 메트릭 수집 + JSON 저장

---

## start 명령

### Step 1: 인자 검증

- `task-id`: T1 / T2 / T3 / T4
- `harness`: off / root / module

오류 시 출력 후 종료:
```
사용법: /harness-validate start {T1|T2|T3|T4} {off|root|module}
```

### Step 2: 세션 파일 생성

Bash tool 로 현재 시각을 기록하고 세션 파일을 생성한다.

```bash
mkdir -p docs/superpowers/validation
python3 -c "
import json, time
from datetime import datetime, timezone
data = {
  'task_id': '{task-id}',
  'harness': '{harness}',
  'started_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
  'started_ms': int(time.time() * 1000)
}
print(json.dumps(data, indent=2))
" > docs/superpowers/validation/.session.json
cat docs/superpowers/validation/.session.json
```

### Step 3: input prompt 표시

task-id 별 input prompt:

| task-id | 복잡도 | input prompt |
|---|---|---|
| T1 | S | `미사용 리소스 파일과 미사용 모델 클래스를 찾아서 정리해줘.` |
| T2 | M | `{object 클래스명}을 Hilt DI로 전환해줘.` |
| T3 | M | `{모듈명}에서 불필요한 외부 의존성을 찾아 제거해줘.` |
| T4 | L | `{클래스명}을 {대상 모듈}로 이동해줘.` |

T2·T3·T4 는 대상 클래스명/모듈명을 고정해서 매 측정마다 동일하게 사용한다.

아래 메시지를 출력하고 대기한다:

```
측정 시작 [{task-id} / harness={harness}]
─────────────────────────────────────────
아래 prompt 를 그대로 입력하세요:

  {해당 task 의 input prompt}

─────────────────────────────────────────
완료 → acceptance criteria 검증 → /harness-validate done
```

---

## done 명령

### Step 1: 세션 파일 확인

`docs/superpowers/validation/.session.json` 존재 여부 확인.
없으면 출력 후 종료:
```
실행 중인 측정 세션이 없습니다. 먼저 /harness-validate start 를 실행하세요.
```

### Step 2: 자동 메트릭 수집

Bash tool 로 duration 계산:

```bash
python3 -c "
import json, time
with open('docs/superpowers/validation/.session.json') as f:
    s = json.load(f)
duration_ms = int(time.time() * 1000) - s['started_ms']
print(f'task_id  : {s[\"task_id\"]}')
print(f'harness  : {s[\"harness\"]}')
print(f'started  : {s[\"started_at\"]}')
print(f'duration : {duration_ms} ms ({duration_ms // 60000} 분)')
"
```

### Step 3: 사용자에게 세션 통계 입력 요청

아래 안내를 출력하고 값을 입력받는다.

```
Claude Code 세션 통계를 확인해 입력해 주세요.
(우측 하단 또는 Esc → 세션 정보에서 확인)

[자동 수집 항목 — 숫자만 입력]
1. tool_call_total  (Read + Edit + Bash + Grep + Write 합계):
2. input_tokens:
3. output_tokens:
4. cache_read_input_tokens:
5. cache_creation_input_tokens:
6. turn_count (user→assistant 응답 쌍 수):

[tool_call_breakdown — 도구별 카운트]
예) Read:5 Edit:3 Bash:2 Grep:1 Write:1
```

입력받은 값을 파싱해서 automated 객체로 보관한다.

### Step 4: 수동 메트릭 — 6개 질문 순차

질문을 한 번에 하나씩 출력하고 응답을 기다린다.

```
Q1. 첫 응답의 코드가 그대로 동작했나요? [y/n]
Q2. 존재하지 않는 API/모듈을 참조한 횟수는? [숫자]
Q3. 결과 코드가 CONVENTIONS.md 규칙을 얼마나 따르나요? [0-10]
Q4. 기존 유틸을 재사용한 비율은? [0-10]
Q5. 사용자가 수정한 라인 수는? [숫자]
Q6. 전반적 품질 점수 [0-10]
```

### Step 5: JSON 저장

세션 파일과 수집한 값으로 결과 JSON 을 Write tool 로 저장한다.

저장 경로:
```
docs/superpowers/validation/{YYYYMMDD-HHMM}-{task_id}-{harness}.json
```

JSON 스키마:
```json
{
  "timestamp": "{started_at}",
  "task_id": "{task_id}",
  "harness": "{harness}",
  "automated": {
    "tool_call_total": 0,
    "tool_call_breakdown": { "Read": 0, "Edit": 0, "Bash": 0, "Grep": 0, "Write": 0 },
    "input_tokens": 0,
    "output_tokens": 0,
    "cache_read_input_tokens": 0,
    "cache_creation_input_tokens": 0,
    "turn_count": 0,
    "duration_ms": 0
  },
  "manual": {
    "first_attempt_success": true,
    "hallucination_count": 0,
    "convention_adherence": 0,
    "reuse_rate": 0,
    "correction_lines": 0,
    "subjective_quality": 0
  }
}
```

### Step 6: 세션 파일 정리 + 완료 안내

```bash
rm docs/superpowers/validation/.session.json
```

```
✓ 저장 완료: {저장된 파일 경로}

다음 측정 준비:
  git checkout master
  git branch -D {현재 trial branch 명}
```
