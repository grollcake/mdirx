# Breadcrumb 상호작용 요건

## 개요

각 패널 헤더의 breadcrumb는 현재 경로를 세그먼트로 표시하면서, **세그먼트 클릭으로 상위 이동**, **더블클릭/⌘L로 주소 입력 모드 진입**, **트레일링 히스토리 버튼**의 세 가지 진입점을 제공한다.

---

## 핵심 요건

### R1. 세그먼트 단일 클릭 → 해당 경로로 이동
- breadcrumb의 각 세그먼트(예: `/ › Users › rollcake › lab`)는 버튼이며, 단일 클릭 시 해당 패널을 활성화하고 그 경로로 navigate.
- 클릭은 해당 세그먼트 폴더로 이동, parent ascend 아님.

### R2. 더블클릭 / ⌘L → 주소 입력 모드
- breadcrumb 영역 어디에든 더블클릭하면 활성 패널이 주소 입력 모드로 들어간다.
- 키보드 단축키 `⌘L`도 동일 효과.
- 상세 동작은 [`address-bar-history.md`](address-bar-history.md) R2 참조.

### R3. 마운트 볼륨 루트 라벨
- breadcrumb 루트 세그먼트는 시스템 볼륨(`/`)인 경우 `/`로 표시.
- 외장 마운트 볼륨에 속한 경로면 그 볼륨의 `name`(예: `Time Machine`)을 루트 라벨로 사용.

### R4. 트레일링 히스토리 버튼은 두 모드 모두에 존재
- breadcrumb 모드와 주소 입력 모드 모두 path bar 오른쪽 끝에 히스토리 메뉴 버튼이 보인다.
- 버튼 클릭은 메뉴만 열고 주소 입력 모드로 자동 전환하지 않는다.
- accessibility id: `pane.<slot>.path.history`.

### R5. 한 줄 높이 유지
- 히스토리 버튼·세그먼트 텍스트가 path bar의 높이를 키우면 안 된다 (`PaneHeaderView` minHeight 28pt 가이드).
- 버튼은 trailing accessory로 배치, 세그먼트는 가로 스크롤로 처리.

---

## 안티패턴 (하지 말 것)

- 세그먼트를 단순 텍스트로만 표시(클릭 불가) — 단축키만으로 상위 이동을 강제.
- 히스토리 버튼 클릭이 주소 입력 모드까지 함께 켜는 동작 — 사용자가 의도하지 않은 편집 모드 진입.
- 볼륨 라벨을 path 마지막 컴포넌트로 표시(예: `Volumes/Time Machine`) — 루트 세그먼트로 끌어올려야 한다.

## 참고
- [`Features/Pane/PaneHeaderView.swift`](../../Features/Pane/PaneHeaderView.swift)
- [`Features/Pane/BreadcrumbView.swift`](../../Features/Pane/BreadcrumbView.swift)
- [`Features/AddressBar/AddressBarView.swift`](../../Features/AddressBar/AddressBarView.swift)
