# ui-guide 모듈

호출자 (`/harness`, `/harness-edit`) 가 Read tool 로 읽고 지침을 따른다. 디자인 시스템 코드 감지 여부에 따라 분기한다.

## 대상 파일

`docs/UI_GUIDE.md`

## 사전 스캔

### 감지 로직

**Android**:
- Glob: `**/ui/theme/Color.kt`, `**/ui/theme/Theme.kt`

**iOS**:
- Glob: `**/Assets.xcassets/**/Contents.json`, `**/Theme.swift`, `**/DesignSystem*.swift`
- 결과가 비어있으면 `extension Color` / `extension UIColor` 같은 색상 확장 코드를 Grep 으로 탐색해 fallback.

### 분기 처리

#### 감지 실패 시

```
디자인 시스템 코드가 감지되지 않았습니다.
docs/UI_GUIDE.md 를 생성할까요? [y/N]
```

- `N` (기본): **파일 생성하지 않음**. CLAUDE.md 의 `@docs/UI_GUIDE.md` 참조는 그대로 유지. 팀원이 나중에 수동으로 추가할 때 자동 가드레일 연결.
- `y`: 빈 템플릿 생성 — 모든 섹션 값을 `[TBD]` 로.

#### 감지 성공 시

1. Color.kt 또는 `.colorset` 에서 색상 토큰 자동 추출.
2. Theme.kt 에서 typography / shape 추출.
3. 사용자에게 두 개의 대화형 질문 (s1 디자인 원칙, s3 컴포넌트 규칙).

### 결과 형식

- 색상 시스템 (Material3 / 커스텀 팔레트 / 단색 기반 등)
- typography 종류
- shape (rounded 수준)
- 색상 토큰 표 (자동 추출)

## 섹션 목록

| 섹션 ID | 헤더 | 타입 | 질문 수 |
|--------|-----|-----|--------|
| s1 | `## 원칙` | 대화형 | 1 |
| s2 | `## 색상` | 자동 | 0 |
| s3 | `## 컴포넌트` | 대화형 | 1 |
| s4 | `## AI 슬롭 금지 (하지 마라)` | 정적 | 0 |

## 섹션별 생성 로직

### s1: 원칙 (대화형, 감지 성공 시만)

```
[디자인 원칙 1~3 개]

레포 스캔 결과 (추정):
  - 색상 시스템: {Material3 / 커스텀 팔레트 / 단색 기반 등}
  - typography: {MaterialTypography / 커스텀 등}
  - shape: {rounded 수준}

아래 중 가깝거나 직접 입력해주세요:
  1) {원칙 예시 1} (매칭: {근거})
  2) {원칙 예시 2} (매칭: {근거})
  3) {원칙 예시 3} (매칭: {근거})
  4) 직접 입력

번호 선택 또는 직접 입력 (건너뛰기 시 Enter → [TBD]):
```

#### 원칙 예시 (스캔 매칭)

| 감지 패턴 | 원칙 예시 |
|----------|---------|
| Material3 색상 토큰 | "Material3 표준 준수, 커스텀 컬러 최소화" |
| colorScheme 에 light / dark 둘 다 정의 | "다크모드 우선 설계" |
| rounded shape 토큰 존재 | "부드러운 shape 기반, 각진 UI 지양" |
| 고정된 typography scale | "Typography 는 토큰만 사용, inline fontSize 지정 금지" |
| 커스텀 팔레트 | "브랜드 컬러 강조, 배경은 최소화된 뉴트럴" |

### s2: 색상 (자동)

자동 추출된 색상 토큰을 표 형태로 채운다.

### s3: 컴포넌트 (대화형, 감지 성공 시만)

```
[컴포넌트 커스터마이징 규칙]

아래 중 가깝거나 직접 입력해주세요:
  1) {규칙 예시 1} (매칭: {근거})
  2) {규칙 예시 2} (매칭: {근거})
  3) 직접 입력

번호 선택 또는 직접 입력 (건너뛰기 시 Enter → [TBD]):
```

#### 규칙 예시 (스캔 매칭)

| 감지 패턴 | 규칙 예시 |
|----------|---------|
| Card composable 사용 | "Card 는 elevation 0, rounded 12dp 고정" |
| M3 Button 사용 | "Button 은 M3 Variant 만 사용 (Filled / Outlined / Text)" |
| 커스텀 Icon | "Icon 은 20dp / 24dp 두 사이즈만 사용" |

스캔 매칭 실패 시 일반 템플릿, `(일반 템플릿)` 표기.

### s4: AI 슬롭 금지 (정적)

대화 없음. 출력 템플릿 본문을 그대로 기록.

### 건너뛰기 처리

빈 줄 / `건너뛰기` / 등 → `[TBD]`.

## 출력 템플릿

````markdown
# UI 디자인 가이드

## 원칙
{s1 답변 또는 [TBD]}

## 색상
{s2 자동 추출된 색상 토큰 표}

## 컴포넌트
{s3 답변 또는 [TBD]}

## AI 슬롭 금지 (하지 마라)
- `backdrop-filter: blur()` — glass morphism
- gradient text (배경 그라데이션 텍스트)
- "Powered by AI" 배지
- box-shadow 글로우 애니메이션
- 보라/인디고 브랜드 색상 ("AI = 보라색" 클리셰)
- 배경 gradient orb (blur-3xl 원형)
````
