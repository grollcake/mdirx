# EXAMPLE — 듀얼 패널 MVP 골격

## 사용자 요구 (정제)

- **정제:** MdirX 첫 창에서 Norton Command·Mdir 계열처럼 **좌우 두 패널 레이아웃**을 먼저 갖추고, **키보드로 활성 패널만 전환**할 수 있게 해 달라. 디렉터리 목록·파일 연산은 아직 넣지 말고 **검증 가능한 뼈대**만 만들면 된다.
- **원문 뉘앙스(가상 예시):** “일단 화면 반반 나누고 탭으로 포커스만 옮기게 해줘. 리스트는 다음에.”
- **의도 보존:** 사용자는 “전체 파일 매니저”가 아니라 **듀얼 패널 UX의 체감**을 가장 먼저 확인하고 싶다는 뜻이므로, 경로는 문자열 표시 수준으로만 두어도 된다.

## 개요

좌·우 두 개의 디렉터리 목록 영역을 갖는 창을 SwiftUI로 띄우고, 탭 키로 포커스 패널만 전환한다. 실제 파일 시스템 나열·복사 등은 범위 밖이며, 고정 샘플 경로 또는 빈 상태 플레이스홀더로 검증 가능한 뼈대만 만든다.

## 요구사항
- **UI**: 하나의 윈도우에 좌우 두 컬럼(비율 대략 1:1), 각 컬럼 상단에 현재 경로(문자열 표시만).
- **동작**: `Tab`으로 “활성 패널” 전환 시 시각적 강조(테두리 또는 배경 틴트). 한 패널만 키보드 포커스를 가진다고 가정.
- **데이터**: 최소한 `leftPath` / `rightPath` 두 문자열 상태. 초기값은 `FileManager.default.homeDirectoryForCurrentUser.path` 동일 또는 샘플 경로.
- **성능/제약**: macOS 15+, Swift 6, SwiftUI만으로 구성(AppKit 래핑은 후속).

## 수도 코드

```
ON app launch:
  leftPath  ← home (or placeholder)
  rightPath ← home (or placeholder)
  activePanel ← .left

ON Tab key:
  activePanel ← toggle(left, right)
  update accent for list columns

RENDER:
  HStack { leftColumn(state: leftPath, isActive: activePanel == .left),
           rightColumn(state: rightPath, isActive: activePanel == .right) }
```

## 아키텍처

- **View**: `ContentView` — `HStack` + 두 개의 `PanelColumnView`(또는 `NavigationSplitView` 대신 단순 `VStack` 제목+리스트 자리).
- **상태**: `@Observable` 루트(예: `BrowserSession`)가 `leftPath`, `rightPath`, `activePanel` 보유; `@Bindable`로 하위에 전달.
- **데이터 흐름**: 단방향, 경로는 당분간 사용자 입력 없이 상수에 가깝게 유지해도 됨.
- **외부 의존성**: 없음(표준 라이브러리·SwiftUI만).

## 통과 조건

- [ ] 앱 실행 직후 좌우 두 패널이 동시에 보인다.
- [ ] `Tab` 입력 시 좌↔우 활성 표시가 매 입력마다 번갈아 바뀐다.
- [ ] 각 패널에 “경로 문자열”이 읽기 가능한 형태로 표시된다.
- [ ] 사용자 수동 검증 후 OK를 받기 전까지 이 문서·파일명 상태는 `done`으로 바꾸지 않는다.

## 구현 체크리스트

- [ ] Xcode 프로젝트 또는 SPM 실행 가능 타깃에 SwiftUI 앱 엔트리 추가
- [ ] `BrowserSession`(또는 동등) `@Observable` 모델
- [ ] `PanelColumnView`: 경로 라벨 + (선택) `List` 자리 더미 1~행
- [ ] `.onKeyPress(.tab)` 또는 `SwiftUI` 키보드 단축 처리로 패널 토글

## 테스트 케이스

- **정상**: 연속 `Tab` 여러 번 시 활성 패널이 좌→우→좌로 안정적으로 순환한다.
- **엣지**: 윈도우 포커스가 앱 밖으로 나갔다 돌아와도 상태가 유지된다(재현 가능하면).
- **에러**: 키 이벤트 미포착 시 대체 수단(임시 버튼으로 패널 전환)을 메모해 두고 통과 조건에서 제외할지 결정.

---

**EXAMPLE** — 샘플 계획 문서. **상태:** `todo` — 본문·파일명 `{상태}`는 함께 갱신한다.
