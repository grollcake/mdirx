# SwiftUI Table 행 클릭 영역과 custom row 레이아웃

## 상황 / 의도

macOS SwiftUI 파일 목록에서 마우스 단일 클릭으로 패널을 활성화하고, 더블클릭으로 폴더 진입/파일 실행을 처리하려 했다. 또한 활성 패널의 선택 행만 파란색으로 보이고, 비활성 패널 선택은 muted 상태로 보여야 했다.

## 잘못된 접근

`TableColumn` 셀마다 gesture modifier 와 선택 배경을 붙였다. 이 방식은 텍스트/셀 content 영역에만 적용되고, 컬럼 사이 공간이나 행의 남는 폭은 `Table` row chrome 영역이라 클릭 대상이 되지 않았다.

그 다음 `Table` 을 custom row list 로 바꾸면서 `Ext`/`Size`/`Time` 컬럼 폭을 고정값으로 크게 잡았다. 한 패널 폭보다 고정 폭 합계가 커져 `Name` 컬럼이 화면 밖으로 밀리고, 목록이 잘린 것처럼 보였다.

## 올바른 해결

행 전체가 하나의 루트 view 가 되도록 custom header + `ScrollView`/`LazyVStack` row 로 구성한다. 선택 배경, accessibility identifier/value, 단일 클릭, 더블클릭 gesture 는 각 행 루트가 소유하게 한다.

custom row 로 전환할 때는 컬럼 폭을 상수 합계로 고정하지 않는다. `GeometryReader` 로 현재 패널 폭을 받고, compact/regular layout 을 계산해 이름 컬럼이 남은 폭을 차지하게 만든다.

## 검증

- UI 테스트에서 행의 이름 텍스트가 아닌 오른쪽 영역(`dx: 0.75`)을 탭해도 패널 활성화와 선택 상태가 바뀌는지 확인했다.
- `xcodebuild test -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS'` 통과.

## 참고

- 계획 문서: `.plan/0516-1726-mouse-activation-and-doubleclick.done.md`
