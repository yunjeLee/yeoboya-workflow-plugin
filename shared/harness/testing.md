# testing 모듈

호출자 (`/harness`, `/harness-edit`) 가 Read tool 로 읽고 지침을 따른다. 4 개 대화형 질문 + 자동 라이브러리 수집.

## 대상 파일

`docs/TESTING.md`

## 사전 스캔

질문 시작 전 아래 소스를 Read / Glob / Bash 로 확인한다.

| 소스 | 용도 |
|------|------|
| `src/test/**/*.kt`, `src/androidTest/**/*.kt` (Android) | 테스트 디렉토리 존재 및 샘플 파일 |
| `Tests/**/*.swift`, `*Tests/**/*.swift` (iOS) | iOS 테스트 파일 |
| `libs.versions.toml`, `build.gradle(.kts)` | JUnit, MockK, Turbine, Espresso 등 감지 |
| `Package.swift`, `Podfile` | XCTest, Nimble, Quick 등 감지 |
| `.github/workflows/*.yml`, `Jenkinsfile`, `bitrise.yml` | CI 에서 테스트 실행 여부 |

### 결과 형식

- 테스트 디렉토리 존재 / 부재
- 기존 테스트 파일 샘플 1~2 개의 네이밍 패턴
- 사용 라이브러리 목록 (s5 자동 채움 용)
- CI 설정 존재 / 부재

## 섹션 목록

| 섹션 ID | 헤더 | 타입 | 질문 수 |
|--------|-----|-----|--------|
| s1 | `## 테스트 레벨` | 대화형 | 1 |
| s2 | `## 네이밍 규칙` | 대화형 | 1 |
| s3 | `## 커버리지 목표` | 대화형 | 1 |
| s4 | `## CI 연동` | 대화형 | 1 |
| s5 | `## 사용 라이브러리` | 자동 | 0 |

## 섹션별 생성 로직

각 대화형 질문은 prd 모듈의 공통 출력 형식 (레포 스캔 결과 → 예시 매칭 → 선택 또는 직접 입력) 을 그대로 따른다. 건너뛰기 시 `[TBD]`.

### s1 예시 (테스트 레벨)

- 1) unit 만 (ViewModel / UseCase / Mapper)  (매칭: `src/test` 있음, `androidTest` 없음)
- 2) unit + integration (DB / Repository 포함)  (매칭: Room 또는 Realm 감지)
- 3) unit + instrumented (기기 테스트 포함)  (매칭: `androidTest` 있음)
- 4) 없음 (점진 도입 예정)  (매칭: 테스트 디렉토리 없음)
- 5) 직접 입력
- 6) [TBD]

### s2 예시 (네이밍 규칙)

- 1) BDD (`given_when_then`)  (매칭: 기존 샘플에서 `given_when_then` 패턴 감지)
- 2) 한글 백틱 (`` `로그인 성공 시 토큰 저장`() ``)  (매칭: 한글 테스트명 감지)
- 3) camelCase 서술 (`loginWithValidCreds_returnsToken`)  (매칭: 일반 JUnit 패턴)
- 4) 직접 입력
- 5) [TBD]

### s3 예시 (커버리지)

- 1) 없음 — 중요한 비즈니스 로직만 우선 (일반 템플릿)
- 2) domain 계층 80% + ViewModel 70% (일반 템플릿)
- 3) 전체 라인 60% (일반 템플릿)
- 4) 직접 입력
- 5) [TBD]

### s4 예시 (CI 연동)

- 1) 모든 PR 에서 전체 테스트  (매칭: `.github/workflows` 에 `test` 스텝 감지)
- 2) PR 에서 unit 만, main 머지 시 전체  (일반 템플릿)
- 3) 로컬만 (CI 없음)  (매칭: CI 파일 없음)
- 4) 직접 입력
- 5) [TBD]

### s5: 사용 라이브러리 (자동)

`build.gradle(.kts)`, `libs.versions.toml`, `Podfile`, `Package.swift` 에서 감지된 테스트 관련 라이브러리 목록을 자동 추출한다 (JUnit, MockK, Turbine, Espresso, XCTest, Nimble, Quick 등). 부재 시 `[TBD]`.

## 출력 템플릿

````markdown
# 테스트 전략

## 테스트 레벨
{s1 답변 또는 [TBD]}

## 네이밍 규칙
{s2 답변 또는 [TBD]}

예시:
{기존 샘플 1 줄 또는 선택된 네이밍 규칙 예시 1 줄}

## 커버리지 목표
{s3 답변 또는 [TBD]}

## CI 연동
{s4 답변 또는 [TBD]}

## 사용 라이브러리
{s5 자동 스캔 결과 목록 또는 [TBD]}
````

### 전부 건너뛰기 시

파일 최상단에 주석 추가:

```
<!-- 이 파일은 아직 채워지지 않았습니다. /harness 또는 /harness-edit 으로 다시 작성하거나 직접 편집하세요. -->
```
