## Step 1: 입력 수신

- **대상**: `LoginButton` (신규 파일)
- **참고 디자인**: 라운드 코너(RoundedCornerShape) + Primary 색상 버튼

---

## Step 2: @Preview 코드 생성

**제안 파일 경로**: `app/src/main/java/com/yeoboya/ui/component/LoginButton.kt`

```kotlin
package com.yeoboya.ui.component

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.yeoboya.ui.theme.AppTheme

@Composable
fun LoginButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp),
        enabled = enabled,
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary,
            disabledContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f),
            disabledContentColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.6f),
        ),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
        )
    }
}

@Preview(showBackground = true)
@Composable
fun LoginButtonPreview() {
    AppTheme {
        LoginButton(
            text = "로그인",
            onClick = {},
        )
    }
}

@Preview(showBackground = true, name = "LoginButton - Disabled")
@Composable
fun LoginButtonDisabledPreview() {
    AppTheme {
        LoginButton(
            text = "로그인",
            enabled = false,
            onClick = {},
        )
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
