# `scripts/gen_xcode_pbx.py`에 새 Swift 파일 등록: 4곳 일관 추가

## 상황 / 의도
`KoreanShortcutNormalizer.swift`/`KoreanShortcutNormalizerTests.swift` 두 파일을 추가하고 `python3 scripts/gen_xcode_pbx.py` 만 다시 돌렸더니 빌드가 `cannot find 'KoreanShortcutNormalizer' in scope`로 실패했다. 파일은 디스크에 있고 import도 필요 없었지만, **pbxproj 생성 스크립트에 ID·참조·그룹·빌드 페이즈를 추가하지 않으면 컴파일 대상에 포함되지 않는다**.

## 잘못된 접근
`gen_xcode_pbx.py`가 디렉터리를 자동 스캔할 거라 가정하고 파일만 새로 만들고 스크립트 재실행. → 스크립트는 **하드코딩 화이트리스트** 기반이라 새 파일이 누락된다.

## 올바른 해결
새 파일 1개를 추가할 때 스크립트의 다음 **모든 곳에 일관되게 짧은 식별자를 넣어야** 한다.

체크리스트 (앱 src 기준, test는 `_TEST` suffix 동일 패턴):

1. **UID 등록 (상단 `U = {k: uid() ...}` 리스트)**
   - `FR_<NAME>` (FileReference), `BF_<NAME>` (BuildFile) 두 키 추가.
2. **`PBXBuildFile` 섹션** — `BF_<NAME>` 한 줄.
3. **`PBXFileReference` 섹션** — `FR_<NAME>` 한 줄.
4. **소속 그룹의 children 리스트** (예: `DUAL_GRP /* DualPane */` 안) — `FR_<NAME>` 한 줄.
5. **해당 타겟의 `PBXSourcesBuildPhase` 파일 리스트** — `BF_<NAME>` 한 줄.

5곳 중 한 군데만 빠뜨려도 빌드가 깨진다. 빌드 에러 메시지가 "cannot find ... in scope"여도 실제 원인은 **컴파일 대상 미등록**일 수 있으니, 이 체크리스트를 먼저 점검할 것.

## 더 깔끔한 대안 (현 시점 미적용)
스크립트가 디렉터리를 walk하면서 자동 등록하면 이 함정 자체가 사라진다. 다만 신뢰성 있는 UID 안정화·정렬 정책이 필요해 현재는 하드코딩 유지. 새 파일을 자주 추가할 때 비용이 커지면 자동화로 전환 검토.

## 참고
- 스크립트: [`scripts/gen_xcode_pbx.py`](../../../scripts/gen_xcode_pbx.py)
- 함께 보면 좋은 노트: [`pbxproj-gen-script-required-for-new-sources.md`](pbxproj-gen-script-required-for-new-sources.md) — 새 파일 추가 후 스크립트 자체를 안 돌렸을 때의 함정.
