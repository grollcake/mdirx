# 전체 코드 리팩토링 + 핵심 요건 영구 문서화

## 사용자 요구 (정제)
- **원문:** "지금 단계에서 전체 코드 리팩토링을 씨게 한번 해보자. 1) 핵심 요건 docs/requirements 추가 2) 비효율 코드 리팩토링 3) 테스트 통과 4) 묻지말고 끝까지."
- **정제:** 실재하는 비효율(증거 기반)만 외과적으로 리팩토링하고, 누락된 영구 요건을 docs/requirements에 문서화한다. 행동 변경 0, 회귀 0. 베이스라인 단위 테스트는 통과 상태에서 시작한다.

## 개요
한 주 분량의 mdirx 코드(25 src + 25 test, ~4400 LoC)에서 누적된 작은 비효율과 미문서화 요건을 정리한다. 신규 기능 추가·아키텍처 변경 없음.

## 요구사항
- 행동(behavior)은 일체 변경하지 않는다. 단위 테스트가 모두 통과하고, 통과를 위해 테스트를 삭제·스킵하지 않는다.
- 새로운 추상화/추측 코드 추가 금지 (Karpathy "Simplicity First").
- 변경되는 라인 하나하나가 PRD 스토리에 직접 추적 가능해야 한다.
- 변경 영역: `Features/Pane/`, `Features/DualPane/`, `Core/Persistence/`, `Tests/UnitTests/`, `docs/requirements/`, `scripts/gen_xcode_pbx.py`.

## 통과 조건
- [x] PRD 스토리 US-001 ~ US-012 모두 `passes: true`
- [x] `xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet` 통과
- [x] `xcodebuild test ... -only-testing:MdirXTests` 통과 (93 passed / 0 failed, 베이스라인 87 + Korean 6 신규)
- [x] 단위 테스트 케이스 감소 없음
- [x] `docs/requirements/`에 신규 요건 문서 6개 + 인덱스 갱신
- [x] 신규 Swift 파일 없음 (요건은 .md, KoreanShortcutNormalizerTests는 이미 등록)
- [x] 완료 후 앱 재빌드·재실행

## 구현 체크리스트
- [x] US-001 요건 문서 6건 작성 + REQUIREMENTS.md 인덱스
- [x] US-002 PathHistoryMenuButton sections 이중 fetch 제거
- [x] US-003 FileListView paneRows 이중 계산 제거
- [x] US-004 selectableEntries 캐싱 — **보류** (speculative perf; @Observable 호환 위험)
- [x] US-005 handleDoubleClick 단일화 — **보류** (Swift Self+MainActor 제약)
- [x] US-006 jumpToDirectory resolvingSymlinksInPath 중복 4건 제거
- [x] US-007 FileListLayout 매직 넘버 → static 상수
- [x] US-008 makePopulatedPane 공유 — **보류** (fixture 의미 차이 + pbxproj 비용)
- [x] US-009 isSelectable 함수 inline + 제거 (descriptionView는 의도된 placeholder)
- [x] US-010 Task 에러 채널 — **이미 존재** (PaneState.load의 catch → state.error)
- [x] US-011 pbxproj 변경 불필요
- [x] US-012 build + 93 tests pass

## 변경 파일 (8)
- `Features/AddressBar/AddressBarView.swift` (US-002)
- `Features/Pane/FileListView.swift` (US-003, US-007)
- `Features/DualPane/PaneState.swift` (US-006, US-009)
- `Features/DualPane/KoreanShortcutNormalizer.swift` (테스트 가능 분리 — normalize(character:modifiers:) 도입)
- `Tests/UnitTests/KoreanShortcutNormalizerTests.swift` (KeyPress 직접 생성 불가 → normalize() 사용으로 수정)
- `docs/requirements/REQUIREMENTS.md` (인덱스 6줄 추가)
- 신규: `docs/requirements/{dual-pane-activation,file-ops-preflight,address-bar-history,pane-rows-composition,name-edit-modal,breadcrumb-interaction}.md` (6개)
