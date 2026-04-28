# workflow 모듈

호출자 (`/harness`, `/harness-edit`) 가 Read tool 로 읽고 지침을 따른다. 정적 템플릿. 대화·스캔 없음.

## 대상 파일

`docs/WORKFLOW.md`

## 사전 스캔

없음. 정적 템플릿이라 스캔 단계가 필요 없다.

## 섹션 목록

| 섹션 ID | 헤더 | 타입 | 질문 수 |
|--------|-----|-----|--------|
| s1 | (전체 파일) | 정적 | 0 |

## 섹션별 생성 로직

### s1: 전체

대화 없음. 아래 출력 템플릿을 그대로 파일에 기록한다.

## 출력 템플릿

````markdown
# 업무 워크플로우

## 우리 팀은 Claude Code 를 이렇게 씁니다

### 기능 개발
/feature <기획서 PDF 또는 설명>
→ 기획서 분석 → brainstorming → feature-plan.md 생성
→ /phase 1 → /phase 2 → ... 단계별 실행
  (각 Task: subagent writer + 테스트 1 회, Phase 완료 후 reviewer)

### 버그 수정
/bugfix <에러 로그 / 설명 / 스크린샷>
→ 유형 분류 (로직 / UI)
→ 로직: systematic-debugging → 복잡도 판단 → TDD 수정
→ UI: 영향 컴포넌트 특정 → 스냅샷 테스트 → 시각 검증

### 보조 도구
- /phase: plan.md 를 단계별로 실행

## 규칙
- 모든 스킬은 docs/ 가드레일을 읽고 동작 (CLAUDE.md 의 @ 참조)
- docs/ 변경 시 팀 공유 필수

## 참고
- 플러그인 README.md
````
