# 파일 삭제 — 휴지통·완전삭제·0-덮어쓰기

## 사용자 요구 (정제)
- **원문:** "파일삭제 기능을 계획해"
- **정제:** 파일 목록에서 현재 선택 항목(선택이 없으면 cursor 항목)을 삭제할 수 있게 한다. [PLAN.md](../PLAN.md)·[docs/PRD.md](../docs/PRD.md)에 이미 정의된 3단계 삭제(휴지통 / 완전삭제 / 0-덮어쓰기)를 기준으로, 안전장치와 테스트 가능한 통과 조건을 먼저 명확히 한다.
- **learnings 반영:** 일괄 작업(복사·이동·삭제 포함)은 `mountedVolumes.map(\.id)` URL 집합으로 볼륨을 명시 제외해야 한다. `isMountedVolume` 플래그만 믿지 않는다.

## 개요
이번 계획은 M1 파일 작업의 다음 단계로, 활성 패널에서 선택된 파일·폴더를 삭제하는 기능을 추가한다. 기본 삭제는 macOS 휴지통 이동이며, 완전삭제와 0-덮어쓰기 삭제는 반드시 확인 다이얼로그를 거친다. Undo, 복구 UI, 백그라운드 진행률 큐는 후속 계획으로 둔다.

## 요구사항
- UI 요구사항
  - `⌫` 또는 `⌘⌫`: 선택 항목을 휴지통으로 이동.
  - `⇧⌘⌫`: 선택 항목을 완전삭제.
  - `⌃⇧⌘⌫`: 선택 파일을 0-덮어쓰기 후 삭제.
  - 완전삭제와 0-덮어쓰기는 확인 sheet를 표시한다. 항목 개수와 대표 파일명을 보여 준다.
  - 삭제 실패 시 활성 패널에 기존 `error` 표시 경로로 오류를 보여 준다.
- 동작 요구사항
  - 삭제 대상은 `PaneState.operationItemURLs()`와 같은 기준을 사용한다: selection 우선, selection이 없으면 cursor 1개.
  - 부모 링크(`..`)와 mounted volume/드라이브 행은 항상 삭제 대상에서 제외한다.
  - 휴지통 삭제는 `FileManager.trashItem(at:resultingItemURL:)` 또는 동등한 macOS API를 사용한다.
  - 완전삭제는 `FileManager.removeItem(at:)`를 사용한다.
  - 0-덮어쓰기 삭제는 일반 파일만 대상으로 한다. 디렉터리나 특수 파일이 포함되면 확인 전 오류로 막는다.
  - 성공 후 활성 패널을 reload하고 삭제된 항목은 selection/cursor에서 제거한다.
- 성능/제약
  - 이번 범위는 동기적 단발 작업이다. 대용량 삭제 진행률·취소는 `OperationQueue` 계획에서 다룬다.
  - 비샌드박스 전제를 유지하되, 권한 오류는 crash 없이 표시한다.

## 수도 코드
```text
on deleteKey(mode):
  targets = activePane.operationItemURLs()
  targets = targets excluding mounted volume ids and parent links
  if targets is empty: return

  if mode == trash:
    fs.trashItems(targets)
    activePane.load()

  if mode == permanent:
    show confirmation(mode, targets)
    if confirmed:
      fs.deleteItemsPermanently(targets)
      activePane.load()

  if mode == zeroOverwrite:
    if targets contains directory or non-regular-file:
      activePane.error = "0-덮어쓰기 삭제는 일반 파일만 가능합니다"
      return
    show confirmation(mode, targets)
    if confirmed:
      fs.zeroOverwriteAndDelete(targets)
      activePane.load()

zeroOverwriteAndDelete(urls):
  for url in urls:
    size = fileSize(url)
    open FileHandle for writing
    write zero buffer repeatedly until size bytes are written
    close handle
    removeItem(url)
```

## 아키텍처
- `Core/FileSystem/FileSystemActor.swift`
  - `trashItems(_:)`, `deleteItemsPermanently(_:)`, `zeroOverwriteAndDelete(_:)` 추가.
  - preflight에서 대상 존재 여부, regular file 여부(0-덮어쓰기), mounted volume 제외 기준을 검증한다.
- `Features/DualPane/PaneState.swift`
  - 기존 `operationItemURLs()` 기준을 재사용하고, 삭제 후 cursor/selection 정합성을 `load(via:)`로 회복한다.
- `Features/DualPane/BrowserSession.swift`
  - `requestDelete(mode:)`, `confirmDelete(mode:)` 흐름을 추가한다.
  - 확인이 필요 없는 휴지통 삭제는 즉시 실행하고, 확인이 필요한 모드는 pending delete 상태를 잡는다.
- `Features/DualPane/DualPaneView.swift` / `Features/Pane`
  - 삭제 키 바인딩 추가.
  - 확인 sheet 컴포넌트 추가(예: `DeleteConfirmModal`).

## 통과 조건
- [ ] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과.
- [ ] `xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath .build/derived CONFIGURATION_BUILD_DIR=$(pwd)/dist -only-testing:MdirXTests` 통과.
- [ ] 휴지통 삭제: 임시 파일 1개 삭제 시 원본 경로에서 사라지고 `trashItems` API가 호출된다(테스트에서는 actor에 주입 가능한 삭제 strategy 또는 임시 디렉터리 검증 사용).
- [ ] 완전삭제: 확인 전에는 파일이 남아 있고, 확인 후 파일/폴더가 제거된다.
- [ ] 0-덮어쓰기 삭제: 일반 파일은 0 write 후 제거되고, 폴더가 섞이면 작업 전 오류로 막는다.
- [ ] 부모 링크와 mounted volume은 삭제 대상에 포함되지 않는다.
- [ ] 삭제 후 활성 패널 reload, selection 비움, cursor는 남은 첫 selectable 항목으로 이동한다.
- [ ] 권한 거부/존재하지 않는 대상 삭제 실패 시 crash 없이 `state.error`로 표시한다.
- [ ] 완료 후 프로젝트 규칙대로 앱을 재빌드·재실행한다.

## 구현 체크리스트
- [ ] `DeleteMode` enum 추가: `.trash`, `.permanent`, `.zeroOverwrite`
- [ ] `FileSystemActor` 삭제 API 3종 추가
- [ ] 0-덮어쓰기 preflight: 일반 파일만 허용, 디렉터리/볼륨/부모 링크 제외
- [ ] `BrowserSession`에 삭제 요청·확인·실행 흐름 추가
- [ ] `DeleteConfirmModal` 추가
- [ ] `DualPaneView` 키 바인딩: `⌫`/`⌘⌫`, `⇧⌘⌫`, `⌃⇧⌘⌫`
- [ ] 단위 테스트: actor 삭제 API, 대상 산정, 확인 전/후 상태
- [ ] UI 테스트 또는 수동 검증 시나리오: 휴지통/완전삭제/0-덮어쓰기 각각 1건
- [ ] `.plan/STATUS.md` 상태 전이 및 완료 시 사용자 OK 후 `done`

## 테스트 케이스
- 정상 케이스
  - 파일 1개 휴지통 이동.
  - 폴더 1개 완전삭제.
  - 여러 파일 selection 삭제.
  - selection이 없을 때 cursor 파일 1개 삭제.
  - 일반 파일 1개 0-덮어쓰기 삭제.
- 엣지 케이스
  - 부모 링크 위에서 삭제 키: 무동작.
  - mounted volume/드라이브 행: 삭제 대상 제외.
  - selection에 삭제 가능 항목과 제외 항목이 섞인 경우: 삭제 가능 항목만 처리.
  - hidden 파일이 보이는 상태에서 선택된 경우: 일반 파일과 동일하게 처리.
- 에러 케이스
  - 완전삭제 확인 취소: 파일 유지.
  - 0-덮어쓰기 대상에 폴더 포함: 작업 전 오류, 아무 항목도 삭제하지 않음.
  - 권한 없는 파일/폴더: crash 없이 오류 표시.
  - 이미 사라진 파일: reload 후 오류 표시 또는 조용히 selection 정리(구현 시 하나로 고정).
