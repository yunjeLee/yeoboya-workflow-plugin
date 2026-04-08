## Step 1: 입력 수신

대상 파일 경로가 명시되지 않음 → 질문 출력:

```
어떤 컴포넌트 또는 화면을 수정하고 싶으신가요?
파일 경로나 Composable 함수명을 알려주세요.
```

가상 케이스로 진행: 홈 화면 카드 컴포넌트 신규 생성

---

## Step 2: @Preview 코드 생성

```kotlin
package com.yeoboya.home.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

data class HomeCardUiState(
    val title: String,
    val description: String,
    val badgeText: String? = null,
)

@Composable
fun HomeCardItem(
    state: HomeCardUiState,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {},
) {
    Card(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = 4.dp, shape = RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(text = state.title, style = MaterialTheme.typography.titleMedium)
                state.badgeText?.let { badge ->
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = MaterialTheme.colorScheme.primaryContainer,
                    ) {
                        Text(
                            text = badge,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                        )
                    }
                }
            }
            Text(
                text = state.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                lineHeight = 22.sp,
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun HomeCardItemPreview() {
    MaterialTheme {
        Column(
            modifier = Modifier.background(MaterialTheme.colorScheme.background).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            HomeCardItem(state = HomeCardUiState("오늘의 업무", "진행 중인 결재 3건.", "3"))
            HomeCardItem(state = HomeCardUiState("공지사항", "2025년 하계 휴가 신청 기간 안내."))
        }
    }
}
```

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
