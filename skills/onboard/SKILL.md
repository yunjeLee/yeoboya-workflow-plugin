---
name: onboard
description: "Claude Code 를 프로젝트에 처음 연결할 때 하네스 문서 세트(CLAUDE.md + docs/)를 자동 생성하거나, 이미 세팅된 레포에서는 신규 팀원에게 프로젝트 구조를 브리핑한다. /onboard, 프로젝트 연결, 하네스 세팅, 온보딩, 신규 팀원 합류, claude code 처음 사용 요청 시 반드시 사용한다."
---

# Onboard Skill — 하네스 기반 프로젝트 온보딩

Claude Code 와 프로젝트를 하네스 기법으로 연결한다. 기존 팀원의 첫 Claude Code 실행 또는 신규 팀원 합류 시 사용한다.

## 트리거
- `/onboard` — 프로젝트 루트에서 실행

---

## Step 1: 플랫폼 자동 감지

`shared/workflow.md` 를 Read tool 로 읽고 **플랫폼 자동 감지** 섹션 지침을 따른다.

> 주의: **하네스 문서 부재 감지** 섹션은 이 스킬에서 건너뛴다 (순환 방지).

---

## Step 2: 상태 감지

아래 파일의 존재 여부를 확인한다 (Glob tool 로 각 경로를 조회해 존재 파일 목록을 얻는다).

**핵심 문서 세트 (4 종)**:
- `CLAUDE.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/ADR.md`

**부가 파일**:
- `docs/UI_GUIDE.md`
- `docs/WORKFLOW.md`

**핵심 문서 세트의 존재 개수**에 따라 Case 를 판단한다. UI_GUIDE / WORKFLOW 는 Case 판단에 영향을 주지 않는다.

| 상태 | Case | 모드 |
|------|------|------|
| 핵심 문서 0 개 | Case 1 | 생성 모드 |
| 핵심 문서 1~3 개 | Case 2 | 보완 모드 (없는 것만) |
| 핵심 문서 4 개 | Case 3 | 브리핑 모드 |

---

## Step 3: Case 분기 실행

### Case 1 또는 Case 2
`shared/onboard-create.md` 를 Read tool 로 읽고 지침을 따른다.
- Case 2 의 경우 "누락된 파일만 생성" 규칙을 **반드시** 준수한다. 기존 파일은 일체 건드리지 않는다.

### Case 3
`shared/onboard-brief.md` 를 Read tool 로 읽고 지침을 따른다.

---

## 완료 리포트

### Case 1 / Case 2
```
## Onboard 완료 리포트 (생성 모드)
- 플랫폼: {Android / iOS}
- 생성 파일: {목록}
- 스킵 파일 (이미 존재): {목록}

다음 단계:
  git add {생성 파일 목록}
  git commit -m "feat: add harness documents via /onboard"

이후 /feature, /bugfix 등을 실행하면 자동으로 하네스 가드레일이 적용됩니다.
```

### Case 3
`shared/onboard-brief.md` 의 출력 포맷에 따라 브리핑 후, 사용자의 후속 질문에 응답한다.
