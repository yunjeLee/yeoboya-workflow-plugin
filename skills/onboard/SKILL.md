---
name: onboard
description: "이미 하네스 문서가 세팅된 프로젝트에서 신규 팀원에게 프로젝트 구조를 브리핑한다. /onboard, 신규 팀원 합류, 프로젝트 구조 파악, 브리핑 요청 시 반드시 사용한다. 하네스 문서가 없으면 /harness 안내 후 종료."
model: opus
---

# Onboard Skill — 신규 팀원 브리핑

이미 하네스 문서가 세팅된 프로젝트에서 신규 팀원에게 프로젝트 구조 / 아키텍처 / 컨벤션을 브리핑한다. **생성/보완은 `/harness` 가 담당**, **수정은 `/harness-edit`**, **검증은 `/harness-critique`** 로 책임이 분리되었다.

## 트리거
- `/onboard` — 프로젝트 루트에서 실행

---

## Step 1: 플랫폼 자동 감지

`shared/workflow.md` 를 Read tool 로 읽고 **플랫폼 자동 감지** 섹션 지침을 따른다.

---

## Step 2: 하네스 문서 존재 확인

Glob tool 로 아래 핵심 6 종 + 부가 2 종 존재 여부를 확인한다.

- 핵심 6: `CLAUDE.md`, `docs/{PRD,ADR,ARCHITECTURE,TESTING,CONVENTIONS}.md`
- 부가 2: `docs/{UI_GUIDE,WORKFLOW}.md`

### 핵심 6 종 중 하나라도 없으면 종료

```
하네스 문서 세트가 완전하지 않습니다.
이 명령은 이미 하네스가 세팅된 프로젝트에서 신규 팀원 브리핑용으로 사용합니다.

먼저 /harness 를 실행해 하네스 문서를 생성하세요.

누락된 파일:
  - {실제 누락 파일 경로 나열}
```

---

## Step 3: 브리핑 실행

`shared/onboard-brief.md` 를 Read tool 로 읽고 그 지침에 따라 브리핑을 출력한다.

---

## Step 4: 후속 질문 응답

브리핑 후 사용자의 후속 질문에 응답한다. 질문이 하네스 수정을 필요로 한다면 `/harness-edit` 를, 검증이 필요하면 `/harness-critique` 를 안내한다.
