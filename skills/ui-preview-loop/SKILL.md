---
name: ui-preview-loop
description: "Composable 또는 View의 UI를 스크린샷 기반 피드백 루프로 반복 수정한다. /ui-preview-loop, UI 수정, Preview 확인, Compose UI 개선, 화면 디자인 수정, '이 화면 다듬어줘', '미리보기 보면서 수정하고 싶어' 요청 시 반드시 사용한다."
---

# UI Preview Loop Skill — UI 피드백 루프

Composable 또는 View의 UI를 스크린샷 기반으로 반복 수정한다.
사용자가 Android Studio Preview를 확인하며 피드백을 주면, 그에 맞게 코드를 수정하는 루프를 제공한다.

## 트리거
- `/ui-preview-loop [컴포넌트명 또는 화면명]`
- `/ui-preview-loop [파일 경로]`
- "이 화면 다듬어줘", "UI 수정하고 싶어" 등 텍스트로 설명해도 동일하게 동작한다.

---

## 공통 지침 참조
- 시작 시: `shared/prompt-refiner.md`를 Read tool로 읽고 지침을 따른다.
- UI 작업 감지 시: `shared/ui-review.md`를 Read tool로 읽고 지침을 따른다.

---

## Step 1: 입력 수신

아래 정보를 확인한다.

- **대상**: Composable 함수명, 파일 경로, 또는 화면 이름 (트리거에서 전달)
- **참고 디자인**: 스크린샷 / 텍스트 명세 / Figma 링크 (선택사항)

대상이 불명확하면 질문한다:
```
어떤 컴포넌트 또는 화면을 수정하고 싶으신가요?
파일 경로나 Composable 함수명을 알려주세요.
```

---

## Step 2: 현재 코드 파악 및 @Preview 코드 생성

대상 파일을 읽고 상태를 파악한다.

**파일이 있는 경우:**
- 기존 코드를 기반으로 @Preview를 추가하거나 개선한다.
- 참고 디자인이 있으면 최대한 반영한다.

**파일이 없는 경우:**
- 입력 내용을 기반으로 새 Composable + @Preview를 생성한다.

@Preview는 반드시 아래 형식으로 포함한다:

```kotlin
@Preview(showBackground = true)
@Composable
fun ComponentNamePreview() {
    AppTheme {
        ComponentName(
            // 대표적인 상태값으로 미리보기 구성
        )
    }
}
```

코드 작성 후 사용자에게 안내한다:
```
코드를 작성했습니다.
Android Studio에서 해당 파일을 열고 Preview 탭을 확인하세요.
```

---

## Step 3: 피드백 루프 (최대 10회)

`shared/ui-review.md`를 Read tool로 읽고 피드백 루프 지침을 따른다.

- 스크린샷 첨부 또는 텍스트 설명 → 수정 후 루프 반복, 회차 증가
- 0 입력 → Step 4(인계)로 진행
- y 입력 → Step 4(완료)로 진행
- 10회 도달 → 0과 동일하게 처리

---

## Step 4: 완료 처리

### y 입력으로 완료된 경우

```bash
git add [수정된 파일 경로]
git commit -m "feat: update [컴포넌트명] UI via preview loop"
```

완료 후 아래 형식으로 변경 이력을 출력한다:

```
[UI Preview Loop 완료]
- 컴포넌트: [컴포넌트명]
- 반복 횟수: N회
- 주요 변경사항:
  1. [변경 내용]
  2. [변경 내용]
```

### 0 입력 또는 10회 도달로 인계된 경우

현재 상태를 저장하고 아래 메시지를 출력한다:

```
[UI 인계]
자동 수정을 종료합니다.
현재까지의 코드를 저장했습니다.
직접 수정 후 '/ui-preview-loop [컴포넌트명]'으로 재시작하거나
다음 작업 진행을 원하면 'continue'를 입력하세요.
```
