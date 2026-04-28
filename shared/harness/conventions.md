# conventions 모듈

호출자 (`/harness`, `/harness-edit`) 가 Read tool 로 읽고 지침을 따른다. 6 개 대화형 질문 (코드 스타일 / 에러 처리 / 로깅 / Claude 작업 스코프 / 커밋 / push 정책) 을 순차로 받는다.

## 대상 파일

`docs/CONVENTIONS.md`

## 사전 스캔

| 소스 | 용도 |
|------|------|
| `.editorconfig`, `detekt.yml`, `ktlint` 설정, `.swiftlint.yml`, `.swiftformat` | 린터/포맷터 감지 |
| 기존 모듈 내 interface/class 네이밍 샘플 | 네이밍 패턴 추출 |
| `sealed class Result`, `sealed interface Result` Grep | Result 패턴 감지 |
| `arrow-kt` 의존성 | Either 함수형 감지 |
| `Timber`, `Log.d`, `os_log`, `SwiftLog` Grep | 로깅 라이브러리 감지 |
| `git log --oneline -20` | 최근 커밋 메시지 패턴 |
| `.github/PULL_REQUEST_TEMPLATE.md`, `.github/CODEOWNERS` | PR 정책 단서 |
| `~/.claude/CLAUDE.md` (참고 동의 시) | "팀 컨벤션", "피해야 할 것", "리팩토링 원칙" 섹션 |

### 결과 형식

- 린터 종류 / 부재
- interface 네이밍 패턴 (접미사 없음 / I 접두사 / Impl 접미사)
- Result / Either 사용 여부
- 로깅 라이브러리
- 최근 커밋 패턴
- PR 정책 단서

## 섹션 목록

| 섹션 ID | 헤더 | 타입 | 질문 수 |
|--------|-----|-----|--------|
| s1 | `## 기본 코드 스타일` | 대화형 | 1 |
| s2 | `## 에러 처리` | 대화형 | 1 |
| s3 | `## 로깅` | 대화형 | 1 |
| s4 | `## Claude 작업 스코프` | 대화형 | 1 |
| s5 | `## 커밋 메시지` | 대화형 | 1 |
| s6 | `## Push 정책` | 대화형 | 1 |

## 섹션별 생성 로직

각 질문은 prd 모듈의 공통 출력 형식을 따른다. 건너뛰기 시 `[TBD]`.

### s1: 기본 코드 스타일

```
[컨벤션 1/6] 기본 코드 스타일 / 네이밍 규칙은?

레포 스캔 결과 (추정):
  - 린터 설정: {ktlint / detekt / swiftlint / 없음}
  - .editorconfig: {있음/없음}
  - 감지된 interface 패턴: {접미사 없음 / `I` 접두사 / `Impl` 접미사}

아래 중:
  1) 린터 설정에 전부 위임 (별도 규칙 없음)  (매칭: 린터 감지)
  2) interface 접미사 없음, implementation 은 `Impl`  (매칭: 기존 코드 패턴)
  3) interface 는 `Xxxable`, class 는 명사  (일반 템플릿)
  4) 직접 입력
  5) [TBD]
```

### s2: 에러 처리

```
[컨벤션 2/6] 에러 처리 방침은?

레포 스캔 결과 (추정):
  - sealed class Result 사용: {있음/없음}
  - arrow-kt Either 사용: {있음/없음}

아래 중:
  1) sealed Result<Success, Error> — 도메인 에러는 Result, 시스템 오류만 throw  (매칭: sealed Result 감지)
  2) Either<Error, Success> 함수형 접근  (매칭: arrow-kt 감지)
  3) try-catch 최소화, 경계 레이어에서만  (일반 템플릿)
  4) runCatching 래퍼로 통일  (일반 템플릿)
  5) 직접 입력
  6) [TBD]
```

### s3: 로깅

```
[컨벤션 3/6] 로깅 방침은?

레포 스캔 결과 (추정):
  - 감지된 로깅 라이브러리: {Timber / Log.d / os_log / SwiftLog / 없음}

아래 중:
  1) Timber only, Log.d 직접 호출 금지  (매칭: Timber 감지)
  2) os_log + signpost  (매칭: iOS)
  3) SwiftLog  (매칭: iOS SwiftLog 감지)
  4) 표준 Log.d / print 사용  (일반 템플릿)
  5) 직접 입력
  6) [TBD]
```

### s4: Claude 작업 스코프 (스캔 없음, 일반 템플릿)

```
[컨벤션 4/6] Claude 가 작업할 때 어디까지 손대도 되나?

(일반 템플릿)

아래 중:
  1) 요청한 파일 + 직접 호출자만 수정. 주변 리팩토링은 별도 PR
  2) 버그 수정 시 같은 파일 내 유사 문제도 함께 수정, 다른 파일은 별도 작업
  3) 발견한 문제는 전부 수정, 큰 변경은 plan.md 로 분리
  4) 요청 범위 엄격 준수 — 타 파일 수정 시 반드시 사용자 승인
  5) 직접 입력
  6) [TBD]
```

### s5: 커밋 메시지

```
[컨벤션 5/6] 커밋 메시지 컨벤션은?

레포 스캔 결과 (추정):
  - 최근 20 개 커밋 메시지 패턴: {Conventional Commits / 한 줄 요약 / 자유 형식 / 한글}

아래 중:
  1) Conventional Commits (feat / fix / refactor / chore / docs 등)  (매칭: 최근 커밋 `feat:` / `fix:` 감지)
  2) 한 줄 요약 + 빈 줄 + 본문  (일반 템플릿)
  3) 자유 형식  (매칭: 패턴 감지 안 됨)
  4) 직접 입력
  5) [TBD]
```

### s6: Push 정책

```
[컨벤션 6/6] Push 정책은?

레포 스캔 결과 (추정):
  - .github/CODEOWNERS: {있음/없음}
  - .github/PULL_REQUEST_TEMPLATE.md: {있음/없음}

아래 중:
  1) master/main 직접 push 금지, PR 필수
  2) 개인 브랜치 push OK, main 은 PR 만
  3) Claude 는 commit 까지, push 는 사용자만
  4) 자유 (Claude 가 직접 push 가능)
  5) 직접 입력
  6) [TBD]
```

## 출력 템플릿

````markdown
# 팀 컨벤션 / 작업 규칙

## 기본 코드 스타일
{s1 답변 또는 [TBD]}

## 에러 처리
{s2 답변 또는 [TBD]}

## 로깅
{s3 답변 또는 [TBD]}

## Claude 작업 스코프
{s4 답변 또는 [TBD]}

## 커밋 메시지
{s5 답변 또는 [TBD]}

## Push 정책
{s6 답변 또는 [TBD]}
````

### 전부 건너뛰기 시

파일 최상단에 주석 추가:

```
<!-- 이 파일은 아직 채워지지 않았습니다. /harness 또는 /harness-edit 으로 다시 작성하거나 직접 편집하세요. -->
```
