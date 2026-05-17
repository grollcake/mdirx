# 감사 보고서 수정사항 반영

## 사용자 요구 (정제)
- 입력 트리거: `.plan/0517-2025-recent-5-commit-audit-report.md` 검토 후 사용자 "yep" — 해명 및 수정 진행.
- 정제: 감사 보고서가 지적한 HIGH 3건 + MEDIUM 2건 + LOW 1건을 빠짐없이 수정한다. 묻지 않고 끝까지.

## 감사 지적 + 수정 결과

| 등급 | 항목 | 수정 |
|----|------|------|
| HIGH 1 | 테스트 명령 누락 | `docs/dev-commands.md` 신설, 표준 빌드·테스트·재실행 명령 명시 |
| HIGH 2 | TextField 전체 선택 미구현 | `selectAllInFocusedField()` 헬퍼(AppKit `NSText.selectAll(_:)` first-responder 디스패치) 추가, popover 진입·index→nil 복귀·⌘L 재진입 3시점에서 호출 |
| HIGH 3 | popover 중 `⌘L` 라우팅 불일치 | `AddressPopoverView`에 `.onKeyPress` 추가 — qwerty 정규화 후 ⌘L이면 TextField로 복귀 + `addressFocusToken` bump → 전체 선택 |
| MEDIUM 1 | Tab → popover close 미구현 | `AddressPopoverView.onKeyPress(.tab)`에서 `onClose()` + `onTabToggleActivePane()` 호출. `PaneHeaderView`/`PaneColumnView`/`DualPaneView`에 toggle 콜백 파이프 추가 |
| MEDIUM 2 | pbxgen learning stale | `gen-pbxproj-new-file-registration-checklist.md`를 `[DEPRECATED]` 배너 + 현재 자동 스캔 워크플로 안내로 재작성. `learnings.md` 인덱스에도 deprecated 표시 |
| LOW 1 | 4 vs 5곳 제목 불일치 | 위와 함께 정정 |

## 통과 조건
- [x] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과
- [x] `xcodebuild test ... CONFIGURATION_BUILD_DIR=$(pwd)/dist -only-testing:MdirXTests` 통과 (99 passed / 0 failed)
- [x] HIGH 1: `docs/dev-commands.md` 존재 및 표준 명령 명시
- [x] HIGH 2: popover 진입 시 TextField 전체 선택 (코드 헬퍼 추가, 수동 검증)
- [x] HIGH 3: popover open 중 ⌘L 재입력 → TextField focus + 전체 선택 (수동 검증)
- [x] MEDIUM 1: popover open 중 Tab → popover close + 활성 패널 toggle (수동 검증)
- [x] MEDIUM 2: pbxgen learning deprecated 표시 + 현재 워크플로 안내
- [x] LOW 1: 4 vs 5곳 표기 정정
- [x] 완료 후 앱 재빌드·재실행

## 구현 체크리스트
- [x] `selectAllInFocusedField()` AppKit 헬퍼 (`AddressBarView.swift`)
- [x] `AddressPopoverView.onAppear` / `onChange(addressListFocusIndex)` / `onChange(addressFocusToken)`에서 호출
- [x] `AddressPopoverView`에 onKeyPress(.tab) + onKeyPress(generic for ⌘L) 추가
- [x] `onTabToggleActivePane` 콜백을 `PaneColumnView` → `PaneHeaderView` → `AddressPopoverView`로 파이프
- [x] `DualPaneView`의 좌·우 `PaneColumnView` 호출에 `{ session.toggleActive() }` 주입
- [x] `gen-pbxproj-new-file-registration-checklist.md` 재작성
- [x] `learnings.md` 인덱스 갱신
- [x] `docs/dev-commands.md` 신설
- [x] 빌드·테스트·재실행

## 미해결·제약
- TextField 전체 선택은 `DispatchQueue.main.async`로 한 틱 양보 후 first responder에 `selectAll:`을 보내는 방식. SwiftUI focus 적용 타이밍에 의존 — 정상 케이스는 검증, 가속 키 입력 같은 엣지에서 한 번 깜빡일 수 있음. 사용자 보고 시 NSViewRepresentable로 격상.
- popover 안에서 ⌘L `.onKeyPress { press in ... }`는 generic action 클로저라 펑션 키와 동일한 SwiftUI 한계(F2/F5/F6은 라우팅 안 됨)가 적용되지만, ⌘L은 문자 키라 영향 없음.
- UI runner는 환경 문제로 여전히 hang. `xcodebuild test`는 `-only-testing:MdirXTests`로 한정해 단위 테스트만 검증한 결과를 인용한다 — 표준 명령 docs에 명시.

## 참고
- 감사 원본: [`.plan/0517-2025-recent-5-commit-audit-report.md`](0517-2025-recent-5-commit-audit-report.md)
- 표준 명령: [`docs/dev-commands.md`](../docs/dev-commands.md)
