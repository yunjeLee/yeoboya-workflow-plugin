# Context Manager

모든 skill은 이 지침을 따라 컨텍스트를 관리한다.

## 핵심 원칙: 1 세션 = 1 목적

각 세션은 하나의 Phase 또는 하나의 Task만 수행한다.
Phase/Task 완료 후 반드시 상태를 저장하고 /clear를 안내한다.

## 상태 파일: .yeoboya-state.json

Phase 완료 시 프로젝트 루트에 저장한다.

{
  "currentSkill": "feature|bugfix|migration|new-app",
  "completedPhase": "brainstorming|writing-plans|task-N",
  "nextPhase": "writing-plans|task-N|task-N+1|done",
  "platform": "Android|iOS",
  "files": ["필요한 파일 경로만"],
  "taskIndex": 0
}

## /clear 유도 시점 3가지

### ① Phase 전환 (매 Phase 완료 후 필수)

Phase가 끝나면 반드시 아래 형식으로 재시작 메시지를 출력한다.

─────────────────────────────────────
[skill명] 재개
- 이전 단계: [completedPhase]
- 다음 단계: [nextPhase 설명]
- 관련 파일: [files 목록]
- 플랫폼: [platform]
─────────────────────────────────────
"/clear 후 위 메시지를 붙여넣어 재시작하세요."

### ② 컨텍스트 50% 초과 (각 Step 시작 전 확인)

각 Step 시작 전 컨텍스트 사용량을 확인한다.
50%를 초과하면 즉시 상태를 저장하고 아래 메시지를 출력한다.

"⚠️ 컨텍스트 사용량이 50%를 초과했습니다.
 compact가 발생하면 작업 품질이 저하될 수 있습니다.
 지금 상태를 저장하고 /clear 후 재시작하는 것을 권장합니다.
 계속 진행하시겠습니까? (y/n)"

### ③ 작업 이탈 감지 (매 입력마다 판단)

사용자의 새 입력이 현재 skill의 목적과 맞지 않는다고 판단되면 권장한다.

판단 기준 (Claude가 의미적으로 판단):
- 현재 /feature 진행 중 → 버그 수정 요청 감지 → /bugfix 권장
- 현재 /feature 진행 중 → 마이그레이션 요청 감지 → /migration 권장
- 현재 /bugfix 진행 중 → 신규 기능 요청 감지 → /feature 권장

출력 형식:
"현재 작업([현재 skill])과 관련 없는 요청 같습니다.
 비용 절약을 위해 /clear 후 /[권장 skill]로 새로 시작하는 건 어떠세요?
 현재 세션에서 계속 진행하려면 'y'를 입력하세요."

강제가 아닌 권장이며, 'y' 입력 시 현재 세션을 유지한다.
