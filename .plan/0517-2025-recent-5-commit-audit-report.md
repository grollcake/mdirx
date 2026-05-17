# 최근 5개 커밋 감사 보고서

## 감사 범위

- 기준 범위: `HEAD~5..HEAD`
- 대상 커밋:
  - `2bf5611` `feat(addressbar): ⌘L 주소 popover + 화살표 탐색 가능한 자주/최근 리스트`
  - `7fd1ff1` `refactor: pbxgen 자동 스캔 + DualPaneView 키바인딩 테이블화`
  - `d72a2ec` `chore(tests): KoreanShortcutNormalizer 테스트 @MainActor 제거`
  - `7afa68b` `refactor: 외과적 비효율 정리 + 핵심 요건 6건 영구 문서화`
  - `faab685` `docs(learnings): 한글 IME 단축키 작업에서 배운 것 3건 추가`

## 결론

판정: **REQUEST CHANGES**

가장 큰 문제는 주소 popover 커밋의 통과 조건 일부가 실제 구현되지 않았고, `.done.md` 계획/커밋 메시지가 검증 상태를 과장하거나 실행 조건을 생략한다는 점이다. 테스트는 `CONFIGURATION_BUILD_DIR`을 같이 지정하지 않으면 `@testable import MdirX` 단계에서 실패하며, 이 함정은 이미 learnings에 기록되어 있는데 최근 커밋 메시지와 계획에는 그 전제가 드러나지 않는다.

## 검증 명령과 관찰

```bash
git log --oneline -5
git diff --stat HEAD~5..HEAD
git diff --name-only HEAD~5..HEAD
xcodebuild build -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist -quiet
xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath /tmp/mdirx-review-dd -quiet
xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath /tmp/mdirx-review-dd2 CONFIGURATION_BUILD_DIR=/Users/rollcake/lab/mdirx/dist -quiet
```

- `xcodebuild build ... -derivedDataPath dist`는 통과.
- `xcodebuild test ... -derivedDataPath /tmp/mdirx-review-dd`는 실패:
  - `Unable to resolve module dependency: 'MdirX'`
  - `@testable import MdirX`
  - `Unable to find a target which creates the host product for value of $(TEST_HOST)`
- `CONFIGURATION_BUILD_DIR=/Users/rollcake/lab/mdirx/dist`를 같이 지정하면 단위 테스트는 진행되지만, 이 환경의 전체 scheme 테스트는 UI test runner가 automation mode 초기화에서 hang/fail.
- 임시 worktree에서 `7afa68b`와 `7fd1ff1`도 같은 방식으로 확인:
  - `CONFIGURATION_BUILD_DIR` 없이 `xcodebuild test ... -derivedDataPath`만 주면 동일하게 `@testable import MdirX` 실패.
  - 즉 이 문제는 `7fd1ff1`만의 신규 회귀라기보다는, 기존 learnings에 적힌 테스트 실행 전제를 최근 완료 보고서들이 누락한 검증/문서화 문제다.

## 발견 사항

### HIGH 1. 테스트 통과 주장이 재현 가능한 명령 형태로 기록되지 않았다

- 증거:
  - `.plan/0517-1905-address-popover.done.md:100`은 `xcodebuild build` / `xcodebuild test -only-testing:MdirXTests` 통과를 완료 조건으로 체크했다.
  - 커밋 `2bf5611` 메시지도 `xcodebuild test → 99 passed / 0 failed`라고 적었다.
  - 하지만 `xcodebuild test -scheme MdirX -destination 'platform=macOS' -derivedDataPath /tmp/mdirx-review-dd -quiet`는 `@testable import MdirX` 해석 실패로 종료된다.
  - `docs/learnings/xcode-spm/test-host-deriveddata-mismatch-with-custom-build-dir.md`에는 이미 `CONFIGURATION_BUILD_DIR`을 같은 derivedDataPath 흐름에 묶어야 한다고 적혀 있다.
- 위험:
  - 다음 작업자가 커밋 메시지/계획의 검증 문구를 믿고 같은 명령을 실행하면 실패한다.
  - CI나 로컬 표준 검증 명령이 정리되지 않아 “테스트 통과”의 의미가 흔들린다.
- 권고:
  - 계획과 커밋 메시지의 검증 문구에 실제 사용한 전체 명령을 남긴다.
  - 표준 테스트 명령을 하나로 고정한다. 예: `xcodebuild test -scheme MdirX -only-testing:MdirXTests -destination 'platform=macOS' -derivedDataPath <path> CONFIGURATION_BUILD_DIR=<repo>/dist`.
  - 가능하면 project 설정에서 `TEST_HOST`/custom build dir 관계를 정리해 `CONFIGURATION_BUILD_DIR` 누락 시에도 오해가 적게 만든다.

### HIGH 2. 주소 popover 진입 시 TextField 전체 선택이 구현되지 않았다

- 증거:
  - 요구사항: `docs/requirements/address-bar-history.md:21`은 진입 시 `currentURL.path`가 전체 선택된 채 표시되어야 한다고 명시.
  - 계획: `.plan/0517-1905-address-popover.done.md:87`도 같은 통과 조건을 `[x]`로 체크.
  - 구현: `Features/AddressBar/AddressBarView.swift:58-65`는 `fieldFocused`만 설정하고 전체 선택 처리가 없다.
- 위험:
  - 사용자가 `⌘L` 후 바로 타이핑하면 기존 경로가 교체되지 않고 커서 위치에 삽입될 수 있다.
  - 주소 입력 UX의 핵심 기대 동작이 깨진다.
- 권고:
  - SwiftUI `TextField`만으로 전체 선택 보장이 어렵다면 AppKit bridge 또는 focus 시 selection 제어용 래퍼를 추가한다.
  - UI 테스트 또는 수동 검증 절차에 “타이핑 시 기존 경로가 완전히 교체되는지”를 포함한다.

### HIGH 3. popover가 열린 상태의 `⌘L` 예외 처리가 요구사항과 다르다

- 증거:
  - 요구사항: `docs/requirements/address-bar-history.md:38-39`는 주소 편집 모드에서 전역 핸들러가 Esc/⌘L 외 키를 `.ignored`로 반환한다고 명시.
  - 구현: `Features/DualPane/DualPaneView.swift:113-116`은 `addressEditing`이면 무조건 `.ignored`.
  - `AddressPopoverView`는 Esc/화살표/Return만 처리하고 `⌘L`은 처리하지 않는다.
- 위험:
  - popover가 열린 상태에서 `⌘L` 재입력으로 TextField 복귀/재선택 같은 주소 모드 재진입 동작을 할 수 없다.
  - 문서화된 키 라우팅 계약과 실제 동작이 불일치한다.
- 권고:
  - `addressEditing` 중 `⌘L`의 기대 동작을 명확히 정한다.
  - 유지할 요건이라면 popover 내부에서 `⌘L`을 처리해 TextField focus + 전체 선택을 수행한다.
  - 유지하지 않을 요건이라면 `address-bar-history.md`와 `shortcuts.md`를 함께 수정한다.

### MEDIUM 1. Tab 전환 시 popover 닫힘 요구가 미완료인데 완료 문서로 남았다

- 증거:
  - 계획 요구사항: `.plan/0517-1905-address-popover.done.md:31`은 “활성 전환(Tab)하면 popover 닫힘”을 요구.
  - 구현 체크리스트: `.plan/0517-1905-address-popover.done.md:111`은 이 항목이 미체크 상태.
  - 현재 구현: `DualPaneView.handleKeyPress`는 `addressEditing`이면 `Tab`을 포함한 모든 전역 키를 `.ignored`한다. `AddressPopoverView`도 Tab 처리가 없다.
- 위험:
  - `.done.md`가 실제 미완료 항목을 포함한다.
  - 사용자가 popover가 열린 상태에서 Tab으로 패널 전환을 기대하면 동작하지 않는다.
- 권고:
  - Tab 요구를 제거할지 구현할지 결정한다.
  - 구현한다면 `AddressPopoverView` 또는 상위 key router에서 Tab을 처리해 현재 popover close + active pane toggle을 수행한다.

### MEDIUM 2. pbxgen 학습 문서가 바로 다음 커밋에서 낡은 지침이 됐다

- 증거:
  - `faab685`의 `docs/learnings/xcode-spm/gen-pbxproj-new-file-registration-checklist.md:6-24`는 `gen_xcode_pbx.py`가 하드코딩 화이트리스트라 새 파일을 여러 곳에 수동 등록해야 한다고 설명.
  - `7fd1ff1`은 `scripts/gen_xcode_pbx.py`를 자동 스캔 방식으로 전면 재작성했다.
  - 현재 `docs/learnings/learnings.md:56`도 “자동 스캔이 아닌 하드코딩”이라고 색인한다.
- 위험:
  - 새 파일 추가 시 다음 작업자가 오래된 체크리스트를 따라 불필요한 수동 등록을 시도할 수 있다.
  - learnings의 신뢰도가 떨어진다.
- 권고:
  - 해당 learning을 “과거 방식”으로 표시하고 현재 방식 링크를 추가한다.
  - 현재 기준 체크리스트는 `python3 scripts/gen_xcode_pbx.py`, `git diff --check`, `xcodebuild build` 중심으로 갱신한다.

### LOW 1. `gen-pbxproj` learning 제목과 본문 수가 불일치한다

- 증거:
  - `docs/learnings/xcode-spm/gen-pbxproj-new-file-registration-checklist.md:1` 제목은 “4곳 일관 추가”.
  - 같은 문서 `14-21`은 5개 항목과 “5곳”을 말한다.
- 위험:
  - 현재 자동 스캔 전환 때문에 우선순위는 낮지만, 그대로 두면 문서 품질 문제가 남는다.
- 권고:
  - 위 MEDIUM 2를 처리하면서 함께 정정한다.

## 커밋별 평가

### `faab685` docs(learnings)

- 신규 learning 자체는 당시 문제 맥락을 기록한다.
- 그러나 `gen-pbxproj-new-file-registration-checklist.md`는 다음 커밋 `7fd1ff1` 이후 현재 구조와 충돌한다.
- 감사 판정: **부분 수정 필요**.

### `7afa68b` refactor + requirements

- `KoreanShortcutNormalizer.normalize` 추출, `FileListLayout` 상수화, 요구사항 문서 추가는 전반적으로 작은 범위다.
- `PaneState`의 `resolvingSymlinksInPath()` 제거는 `jumpToDirectory` 내부에서 다시 resolve하므로 즉시 회귀로 보이지 않는다.
- 다만 새 요구사항 문서가 이후 구현의 기준이 되었고, 그 기준 중 일부가 `2bf5611`에서 충족되지 않았다.
- 감사 판정: **직접 코드 결함은 확인되지 않았으나, 이후 완료 판정 기준으로 쓰인 요건 관리가 중요**.

### `d72a2ec` tests

- `KoreanShortcutNormalizer.normalize`는 MainActor 격리가 아니므로 테스트의 `@MainActor` 제거 자체는 타당하다.
- 감사 판정: **문제 없음**.

### `7fd1ff1` pbxgen + keybinding table

- 자동 스캔 전환은 방향이 맞고 `python3 scripts/gen_xcode_pbx.py && git diff --exit-code -- MdirX.xcodeproj/project.pbxproj scripts/gen_xcode_pbx.py`는 현재 idempotent.
- 다만 검증 보고가 `CONFIGURATION_BUILD_DIR` 전제를 생략하면 테스트 재현성이 깨진다.
- `DualPaneShortcuts` 테이블화는 기존 `.contains` 기반 modifier 매칭을 유지하므로 이번 감사에서 신규 동작 회귀로 확정하지 않았다.
- 감사 판정: **검증 명령 문서화 보강 필요**.

### `2bf5611` address popover

- 핵심 기능은 추가되었지만 다음 통과 조건이 미충족 또는 미확정:
  - TextField 전체 선택 없음.
  - `⌘L` 재처리 요건 불일치.
  - Tab으로 popover 닫기 미구현.
  - 체크리스트 미완료 항목이 남은 상태로 `.done.md`.
- 감사 판정: **수정 필요**.

## 권장 수정 순서

1. `2bf5611` 주소 popover 미완료 항목 수정:
   - TextField 전체 선택.
   - popover 중 `⌘L` 처리 방침 확정 및 구현/문서 수정.
   - Tab close/toggle 요구 구현 또는 계획/요건에서 제거.
2. 테스트 표준 명령 정리:
   - 단위 테스트 표준 명령을 문서화.
   - 커밋/계획의 “테스트 통과” 문구에 전체 명령과 범위를 적도록 규칙화.
3. learnings 갱신:
   - `gen-pbxproj-new-file-registration-checklist.md`를 현재 자동 스캔 구조에 맞게 갱신하거나 deprecated 표시.
4. `.plan/0517-1905-address-popover.done.md` 상태 정리:
   - 실제 미완료 항목을 완료 전제로 두지 않도록 todo/doing 후속 계획을 만든다.

## 남은 리스크

- UI 테스트 runner가 이 환경에서 automation mode 초기화 timeout/hang을 보인다. 코드 결함인지 로컬 권한/환경 문제인지는 분리하지 못했다.
- 실제 macOS UI에서 TextField selection 상태는 코드 정적 분석만으로는 완전히 증명할 수 없다. 현재 코드에는 selection 제어가 없으므로 미구현으로 판정했지만, 최종 수정 후에는 수동/UITest 검증이 필요하다.
- 이 감사는 수정 없이 read-only 중심으로 수행했다. 변경 파일은 이 감사 보고서 1개뿐이다.
