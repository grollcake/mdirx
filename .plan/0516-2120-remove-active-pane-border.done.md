# 활성 패널 파란 테두리 제거

## 사용자 요구 (정제)

- **원문:** "활성팬에 파란색 테두리 나오는거 제거하자"
- **정제:** 활성 패널 전환 시 나타나는 파란색(`Color.accentColor`) 테두리를 제거한다. 비활성 패널의 미세 테두리(`Color.white.opacity(0.15)`) 처리도 통일한다.

## 개요

`PaneColumnView`의 `.overlay` 에서 `isActive` 여부에 따라 파란 테두리를 그리는 코드를 제거한다. 단일 파일 1줄 변경.

## 요구사항

- 활성 패널에 파란 테두리(`Color.accentColor`, lineWidth 2)가 나타나지 않는다.
- 양 패널 모두 테두리 없이 표시한다 (overlay 자체 제거).
- 활성 패널 인식은 커서 하이라이트·행 배경색으로만 구분한다.

## 수도 코드

```
// PaneColumnView.swift 43~46 라인 제거:
// .overlay {
//     RoundedRectangle(cornerRadius: 4)
//         .strokeBorder(isActive ? Color.accentColor : Color.white.opacity(0.15), lineWidth: isActive ? 2 : 1)
// }
```

## 아키텍처

- **수정 파일:** `Features/Pane/PaneColumnView.swift` — overlay 블록 3줄 제거

## 통과 조건

- [ ] 빌드 0 error / 0 warning
- [ ] 앱 실행 후 Tab 으로 패널 전환 시 파란 테두리가 보이지 않는다 (수동 확인)
- [ ] 기존 UI 테스트 전부 통과

## 구현 체크리스트

- [ ] `PaneColumnView.swift` overlay 블록 제거
- [ ] 빌드 확인
- [ ] 앱 재실행·수동 확인
- [ ] STATUS.md 갱신

---

**상태:** `todo`
