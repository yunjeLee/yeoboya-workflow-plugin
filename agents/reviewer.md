# Reviewer Agent

`superpowers:requesting-code-review` 스킬을 사용해 코드 검토를 수행하는 에이전트입니다.

## 사용법

아래 형식으로 요청하면 됩니다.

```
/requesting-code-review 코드 리뷰해줘

  - 구현 내용: {현재 프로젝트}에서 {어떤 작업을 했는지}
  - BASE_SHA: 61dc820 (리뷰 시작 commit id)
  - HEAD_SHA: 21259a2 (리뷰 끝 commit id)
  - 코딩 규칙(선택 사항): {현재 프로젝트 CLAUDE.md 경로}(내 프로젝트의 CLAUDE.md에 코딩규칙이 명시되어 있다면)
```

## 동작 방식

`superpowers:requesting-code-review` 스킬이 아래 순서로 실행됩니다.

1. 입력된 SHA 범위로 `git diff` 를 실행해 변경 내용을 파악한다.
2. `superpowers:code-reviewer` 서브에이전트를 디스패치해 독립적으로 검토한다.
3. 서브에이전트가 결과를 반환하면 심각도별로 피드백을 정리한다.

## 검토 기준 (code-reviewer 기준)

**코드 품질**
- 관심사 분리가 명확한가?
- 타입 안전성, DRY 원칙, 엣지 케이스 처리

**아키텍처**
- 설계 결정의 타당성, 성능·보안 고려

**테스트**
- 실제 로직을 검증하는 테스트인가? 엣지 케이스 커버 여부

**요구사항**
- 계획/기획서의 모든 요구사항을 충족하는가?

**프로덕션 준비도**
- 하위 호환성, 문서화, 명백한 버그 없음

## 검토 결과 형식

```
### Strengths
[잘 된 점 — 구체적으로]

### Issues

#### Critical (반드시 수정)
[버그, 보안 문제, 데이터 손실 위험, 동작 불능]

#### Important (수정 권고)
[아키텍처 문제, 누락 기능, 부실한 에러 처리, 테스트 부족]

#### Minor (선택 개선)
[코드 스타일, 최적화 기회, 문서 개선]

각 이슈마다: 파일:라인 참조 / 문제 내용 / 왜 중요한지 / 수정 방법

### Recommendations
[코드 품질·아키텍처·프로세스 개선 제안]

### Assessment

**Ready to merge?** [Yes / No / With fixes]

**Reasoning:** [기술적 판단 1~2문장]
```

## 피드백 처리 원칙

- **Critical** — 즉시 수정
- **Important** — 다음 작업 전 수정
- **Minor** — 추후 개선 과제로 기록
- 리뷰어가 틀렸다면 기술적 근거를 들어 반박
