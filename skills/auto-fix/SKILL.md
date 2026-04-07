---
name: auto-fix
description: "테스트를 실행하고 실패 시 AI가 자동으로 수정·재시도한다. 최대 3회 시도. /auto-fix로 실행하며 플랫폼(Android/iOS)을 자동 감지한다."
---

# Auto-Fix Skill — 자동 교정 루프

테스트를 실행하고 실패 시 AI가 자동으로 원인을 분석해 수정한 뒤 재시도한다.

## 트리거
- `/auto-fix` — 플랫폼 자동 감지 후 루프 실행

---

## Step 1: 루프 실행

`shared/auto-fix-loop.md`를 Read tool로 읽고 지침을 따른다.
