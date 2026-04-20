# Context Manager

모든 skill은 이 지침을 따라 컨텍스트를 관리한다.

## Phase / Task 계층

- **Phase**: 큰 작업 단계 (brainstorming → writing-plans → 실행 → done)
- **Task**: Phase 내 세부 작업 단위

예시 흐름 (/feature "사용자 인증"):
```
Phase: brainstorming → Phase: writing-plans → task-1 구현 → task-2 구현 → done
```

## 핵심 원칙: 1 세션 = 1 목적

각 세션은 하나의 Phase 또는 하나의 Task만 수행한다.
Phase/Task 완료 후 반드시 상태를 저장하고 /clear를 안내한다.

## 상태는 plan.md 에 산다

별도 상태 파일은 쓰지 않는다. `{skill}-plan.md` 의 Task 체크리스트(`- [ ]` / `- [x]`)가 유일한 완료 기록이다. /clear 후 재시작할 때 Claude 는 plan.md 를 Read 해 진행 상황을 복원한다.

Phase 재시작 메시지의 `이전 단계` / `다음 단계` / `관련 파일` 값은 plan.md 와 직전 대화에서 Claude 가 직접 추출한다.

## /clear 유도 시점 3가지

### ① Phase 전환 (매 Phase 완료 후 필수)

Phase가 끝나면 반드시 아래 형식으로 재시작 메시지를 출력한다.

```
─────────────────────────────────────
[skill명] 재개
- 이전 단계: [completedPhase]
- 다음 단계: [nextPhase] (예: "task-2: 구현 시작", "done: 모든 작업 완료")
- 관련 파일: [files 목록]
- 플랫폼: [platform]
─────────────────────────────────────
```

"/clear 후 위 메시지를 붙여넣어 재시작하세요."

### ② 컨텍스트 50% 초과 (권장 — 강제 장치 없음)

Claude 가 자발적으로 체크한다. 훅/settings 로 강제하지 않으므로 실효성은 모델 판단에 의존한다. 50% 를 넘는다고 느끼면 아래를 **권장**한다 (필수 아님):

```
컨텍스트 사용량이 50% 를 넘었을 가능성이 있습니다.
지금 상태를 저장하고 /clear 후 재시작하는 것을 권장합니다.
계속 진행하시겠습니까? (y/n)
```

> 향후 개선: Claude Code 의 SessionStart / Stop hook 으로 자동 알림화 예정 (별도 spec).

### ③ 작업 이탈 감지 (권장 — 모델 판단 의존)

사용자의 새 입력이 현재 skill 목적과 맞지 않다고 **판단되면** 권장한다. 강제 장치는 없다.

판단 기준:
- 현재 /feature 진행 중 → 명확한 신규 버그 신고 → /bugfix 권장
- 현재 /bugfix 진행 중 → 명확한 신규 기능 요청 → /feature 권장
- 같은 feature 범위 내 자잘한 수정(예: "로그인 UI 추가" → "로그인 검증 로직")은 현재 세션을 유지한다. false positive 최소화 우선.
- 판단이 불확실하면 권장하지 않는다.

출력 형식:
```
현재 작업([현재 skill])과 관련 없는 요청 같습니다.
비용 절약을 위해 /clear 후 /[권장 skill]로 새로 시작하는 건 어떠세요?
현재 세션에서 계속 진행하려면 'y'를 입력하세요.
```

강제가 아닌 권장이며, 'y' 입력 시 현재 세션을 유지한다.
