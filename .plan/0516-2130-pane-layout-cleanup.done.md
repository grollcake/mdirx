# 파일 목록 행 번호 제거 + 패널 구분 컬럼 추가

## 사용자 요구 (정제)

- **원문:** "파일 목록에 번호 나오는거 없애" + "Nexus 캡처1번에 보이는 것처럼 팬 사이에 구분 컬럼 추가해"
- **정제:**
  1. 파일 목록의 `#` 행 번호 컬럼을 제거한다.
  2. 두 패널 사이의 `Divider()`를 NexusFile 스타일의 명확한 세로 구분 컬럼으로 교체한다.

## 개요

`FileListView.swift`에서 행 번호 관련 코드를 제거하고, `DualPaneView.swift`의 `Divider()`를 커스텀 구분 컬럼으로 교체한다.

## 요구사항

### 행 번호 제거
- 헤더의 `#` 컬럼 텍스트 제거
- 각 행의 번호 표시 제거
- `FileListLayout.fixed` 폭을 24pt 줄임 (300 → 276)
- `markerWidth` 프로퍼티 삭제

### 패널 구분 컬럼
- 기존 `Divider()` 대신 `Rectangle().fill(Color.white.opacity(0.12)).frame(width: 4)` 형태의 구분 컬럼
- NexusFile 스타일: 패널 배경보다 약간 밝은 세로 바

## 수도 코드

```
// FileListLayout:
// markerWidth 제거, fixed 300 → 276

// FileListHeader:
// Text("#").frame(width: layout.markerWidth) 제거

// FileListRow body:
// Text("\(row.rowNumber)").frame(width: layout.markerWidth) 제거

// DualPaneView:
// Divider() →
Rectangle()
    .fill(Color.white.opacity(0.12))
    .frame(width: 4)
```

## 아키텍처

- **수정 파일**
  - `Features/Pane/FileListView.swift` — markerWidth 제거 3곳, fixed 수정
  - `Features/DualPane/DualPaneView.swift` — Divider() → 커스텀 Rectangle

## 통과 조건

- [ ] 빌드 0 error / 0 warning
- [ ] 파일 목록에 행 번호가 보이지 않는다
- [ ] 두 패널 사이에 NexusFile 스타일 구분 컬럼이 보인다
- [ ] 기존 테스트 전부 통과

## 구현 체크리스트

- [ ] `FileListLayout.markerWidth` 제거, `fixed` 수정
- [ ] `FileListHeader` `#` 컬럼 제거
- [ ] `FileListRow` 행 번호 표시 제거
- [ ] `DualPaneView` Divider → 커스텀 구분 컬럼
- [ ] 빌드·앱 재실행·수동 확인
- [ ] STATUS.md 갱신

---

**상태:** `todo`
