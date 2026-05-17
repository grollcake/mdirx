# sheet 열려 있어도 부모 .onKeyPress 가 키를 먼저 소비

## 상황 / 의도

`DualPaneView` 에 `.onKeyPress` 전역 핸들러가 있고, `PaneColumnView` 에 `.sheet(item:)` 로 `NameEditModal` 을 띄웠다. 모달 안 TextField 에서 Enter → 확인, ESC → 취소가 동작해야 하는데, 실제로는 Enter 가 파일 리스트의 더블클릭 동작을 실행하고 ESC 는 선택 해제를 실행했다.

## 잘못된 접근

SwiftUI sheet 가 모달이므로 키 이벤트가 자동으로 sheet 로 전달될 것이라 가정했다.

## 올바른 해결

부모의 `.onKeyPress` 클로저 최상단에서 편집 상태를 체크해 `.ignored` 를 반환한다.

```swift
.onKeyPress { press in
    guard session.current.editing == nil else { return .ignored }
    // ... 기존 핸들러
}
```

`.ignored` 를 반환하면 이벤트가 뷰 계층 아래(sheet)로 전달되어 TextField 의 `.onSubmit`, Button 의 `.keyboardShortcut` 이 정상 동작한다.

## 참고

- `Features/DualPane/DualPaneView.swift`
- 커밋: `feat(pane): rename / new folder / new file (F2 / ⌥K / ⌃N)`
