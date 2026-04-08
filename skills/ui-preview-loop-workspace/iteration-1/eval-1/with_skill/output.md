## Step 1: 입력 수신

- **대상 Composable**: `HomeScreen`
- **파일 경로**: `/Users/iyunje/AndroidStudio/dalla/feature/home/src/main/java/com/example/home/HomeScreen.kt`
- **참고 디자인**: 없음

파일 존재 여부 확인: **파일 없음** → 신규 생성 케이스로 처리

---

## Step 2: @Preview 코드 생성

```kotlin
package com.example.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

@Composable
fun HomeScreen(
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = "홈",
            style = MaterialTheme.typography.headlineMedium,
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "홈 화면입니다.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    MaterialTheme {
        HomeScreen()
    }
}
```

코드를 작성했습니다.
Android Studio에서 해당 파일을 열고 Preview 탭을 확인하세요.

---

## Step 3: 피드백 루프

```
─────────────────────────────────────────────
[UI 피드백 요청] (1/10회)
Android Studio에서 Preview를 확인하세요.

- 스크린샷을 첨부하면 문제를 분석하고 수정합니다.
- 원하는 변경사항을 텍스트로 설명해도 됩니다.
- 0을 입력하면 중단하고 현재 상태를 저장합니다.
- y를 입력하면 완료로 처리합니다.
─────────────────────────────────────────────
```

**사용자 응답 대기 중**
