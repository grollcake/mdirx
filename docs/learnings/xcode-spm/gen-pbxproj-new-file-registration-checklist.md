# [DEPRECATED] `scripts/gen_xcode_pbx.py`에 새 Swift 파일 등록: 5곳 일관 추가

> **이 노트는 2026-05-17 18:30(`7fd1ff1`)부터 적용 안 됨.**
> `gen_xcode_pbx.py`가 자동 디렉터리 스캔으로 전환되어 새 Swift 파일은
> `python3 scripts/gen_xcode_pbx.py` 한 번만 다시 돌리면 자동 등록된다.
> 수동 등록 항목은 더 이상 없다.

## 현재 절차 (2026-05-17 18:30 이후)

1. 디스크에 `*.swift` 파일을 만든다.
2. `python3 scripts/gen_xcode_pbx.py` 실행 — `App/`, `Core/`, `Features/`, `DesignSystem/`, `Tests/UnitTests/`, `Tests/UITests/` 하위가 자동 스캔된다.
3. `xcodebuild build` 로 검증.

리소스(Asset/엔타이틀먼트/Localizable) 4건은 여전히 하드코딩 — 그쪽을 새로 추가할 때만 스크립트 본문을 손댄다.

## 과거 함정 (참고용)

자동 스캔 전에는 새 파일 1개마다 스크립트의 **5곳**에 일관 식별자를 넣어야 했다. UID·BuildFile·FileReference·Group children·SourcesBuildPhase. 하나라도 빠지면 "cannot find ... in scope" 빌드 실패. 이번 자동 스캔 도입으로 폐기됨.

## 교훈

- 같은 함정이 반복되면 **함정 자체를 없애는** 자동화가 매뉴얼 체크리스트보다 낫다.
- 새 함정 발견 → learning 작성과 동시에 "이게 자동화 가능한가" 한 번은 묻기.

## 참고

- 현재 스크립트: [`scripts/gen_xcode_pbx.py`](../../../scripts/gen_xcode_pbx.py)
- 자동화 전환 계획: [`.plan/0517-1830-pbxgen-autoscan-and-keybinding-table.done.md`](../../../.plan/0517-1830-pbxgen-autoscan-and-keybinding-table.done.md)
- 함께 보면 좋은 노트: [`pbxproj-gen-script-required-for-new-sources.md`](pbxproj-gen-script-required-for-new-sources.md) — 스크립트 자체를 안 돌렸을 때의 함정 (여전히 유효).
