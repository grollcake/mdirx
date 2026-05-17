# 주소 popover 리스트 스크롤 동기화

## 사용자 요구 (정제)
- 원문: “아래 화살표로 계속 내려가는데 스크롤바는 그대로네. 스크롤동기화. 이것도 아까 지침대로 작업해.”
- 정제: 주소 popover의 히스토리 목록에서 키보드 `↓`/`↑`로 highlight가 이동할 때, 보이는 스크롤 위치도 highlight된 행을 따라 자동으로 이동해야 한다.
- 작업 순서: 계획 작성 → 코드 수정 → 사용자 보고 → 사용자 컨펌 시 learnings 후보 기록 → 커밋/푸시.

## 개요
현재 주소 popover는 `addressListFocusIndex`만 변경하고 `ScrollView` 위치를 갱신하지 않는다. `ScrollViewReader`와 row id를 추가해 highlight 인덱스 변경 시 해당 행이 보이도록 스크롤을 동기화한다.

## 요구사항
- `↓`/`↑` 반복 입력으로 highlight가 보이는 영역 밖으로 이동하려 할 때 스크롤 위치가 따라간다.
- 마우스 hover로 highlight가 바뀌는 경우도 같은 규칙으로 스크롤 상태와 충돌하지 않는다.
- 첫 항목에서 `↑`로 TextField에 복귀하는 동작은 유지한다.
- 리스트가 비어 있거나 TextField focus 상태일 때 불필요한 스크롤 호출을 하지 않는다.
- 새 의존성은 추가하지 않는다.

## 수도 코드
```text
ScrollViewReader proxy:
  ScrollView:
    LazyVStack:
      row(index).id(index)

on addressListFocusIndex change:
  guard let index else return
  guard addressListFlat.indices contains index else return
  withAnimation(short):
    proxy.scrollTo(index, anchor: nearest practical anchor)
```

## 아키텍처
- `Features/AddressBar/AddressBarView.swift`
  - 히스토리 `ScrollView`를 `ScrollViewReader`로 감싼다.
  - 각 row에 stable id로 `index`를 부여한다.
  - `addressListFocusIndex` 변경 시 현재 index로 `scrollTo`를 호출한다.
- `PaneState`의 focus/index 전이 로직은 유지한다.
- 자동 테스트는 상태 전이까지만 보호 가능하므로, 실제 스크롤 동기화는 사용자 수동 확인을 통과 조건에 둔다.

## 통과 조건
- [x] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과.
- [x] `xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist CONFIGURATION_BUILD_DIR=$(pwd)/dist -only-testing:MdirXTests` 통과.
- [x] 앱 재빌드 후 실행 (`dist/MdirX.app`).
- [x] 사용자 수동 확인: `⌘L` → `↓` 반복 시 highlight가 아래로 내려가면 스크롤바/목록도 함께 내려간다.
- [x] 사용자 수동 확인: `↑` 반복 시 highlight가 위로 올라가면 스크롤도 함께 올라간다.
- [x] 사용자 수동 확인: 첫 항목에서 `↑` → TextField 복귀가 유지된다.

## 완료 기록
- 2026-05-17 22:12 사용자 확인: “둘 다 성공.”
- learnings 기록: `docs/learnings/swiftui/popover-highlight-state-is-not-keyboard-focus-or-scroll.md`

## 구현 체크리스트
- [x] `ScrollViewReader` 도입.
- [x] row에 stable scroll id 추가.
- [x] focus index 변경 시 `scrollTo` 호출.
- [x] 빌드·테스트·앱 재실행.

## 테스트 케이스
- 정상: 많은 히스토리 항목에서 `↓` 반복 → highlight와 스크롤 위치 동기화.
- 정상: 아래쪽 항목에서 `↑` 반복 → 스크롤 위치 위로 동기화.
- 엣지: 첫 항목에서 `↑` → TextField 복귀, 스크롤 호출 없음.
- 회귀: `Enter`, `Esc`, `Tab`, `⌘L` 재입력 동작 유지.
