# popover highlight 상태는 키보드 포커스나 스크롤이 아니다

## 상황 / 의도

주소 popover에서 `↓`를 누르면 최근/자주 방문 목록의 highlight가 내려가야 하고, 항목이 보이는 영역 밖으로 이동하면 목록 스크롤도 같이 따라가야 했다.

## 잘못된 접근

기존 구현은 `addressListFocusIndex`만 바꾸면 키보드 탐색이 계속될 것이라고 가정했다. TextField의 첫 `↓`가 `addressListFocusIndex = 0`을 만든 뒤 TextField focus를 껐지만, 리스트나 popover 컨테이너에 새 keyboard focus를 주지 않았다. 그래서 다음 `↑`/`↓`는 처리자 없이 system beep만 났다.

두 번째로, highlight index를 바꾸면 `ScrollView`가 선택 행을 자동으로 따라갈 것이라고 가정했다. SwiftUI `ScrollView`는 내부 상태 변화만으로 위치를 움직이지 않기 때문에, highlight가 화면 밖으로 내려가도 스크롤바는 그대로였다.

## 올바른 해결

highlight index는 시각 상태일 뿐이다. 키보드 탐색 UI에서는 세 가지를 각각 명시적으로 동기화해야 한다.

```swift
@FocusState private var fieldFocused: Bool
@FocusState private var listFocused: Bool

private func syncKeyboardFocus(to listIndex: Int?) {
    let shouldFocusList = listIndex != nil
    fieldFocused = !shouldFocusList
    listFocused = shouldFocusList
}
```

리스트 영역은 `.focusable().focused($listFocused)`로 실제 키 입력을 받을 수 있어야 한다. 스크롤은 `ScrollViewReader`에서 각 row에 stable id를 부여하고, `addressListFocusIndex` 변경 시 `proxy.scrollTo(index, anchor: .center)`를 호출해 별도로 맞춘다.

## 참고

- `Features/AddressBar/AddressBarView.swift`
- `.plan/0517-2206-address-popover-keyfocus.done.md`
- `.plan/0517-2210-address-popover-scrollsync.done.md`
