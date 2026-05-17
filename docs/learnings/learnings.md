# 학습·실수 기록 (`docs/learnings`)

작업 중 겪은 **실수·오해**와 **올바른 해결**만 짧게 남긴다. `.plan/` 의 “하기 전 계획”과 구분한다.

## 완료 승인과 함께

작업 **완료에 대한 사용자 OK** 이후, 에이전트는 **learnings 후보**(새로 배운 것·헤매다 해결한 것·같은 식으로 반복될 수 있는 것)를 사용자에게 **제안**한다. **사용자가 추가를 승인한 항목만** 여기에 문서로 반영한다. 승인 없이 저장소에 쓰지 않는다. 절차·역할은 [`AGENTS.md`](../../AGENTS.md) 와 [`.plan/PLAN.md`](../../.plan/PLAN.md) 의 `done` 조건을 본다.

## 영역

| 디렉터리 | 용도 |
|----------|------|
| [swift/](swift/) | 언어·동시성·표준 라이브러리 |
| [swiftui/](swiftui/) | SwiftUI 뷰·상태·macOS 특이점 |
| [xcode-spm/](xcode-spm/) | Xcode, SPM, 빌드 설정 |
| [git-ci/](git-ci/) | Git, CI, 훅 |
| [macos-sandbox/](macos-sandbox/) | 샌드박스·권한·보안 스코프(필요 시) |

필요하면 디렉터리를 더 둔다.

## 파일명

- `{영역}-{짧은주제}.md` 또는 `YYYY-MM-DD-{주제}.md`
- **한 파일 = 한 주제** (실수 하나 + 해결)

## 본문 최소 뼈대

```markdown
# 제목

## 상황 / 의도
## 잘못된 접근 (선택)
## 올바른 해결
## 참고 (커밋·링크, 선택)
```

새 문서를 추가하면 아래 **목록**에 한 줄만 적는다.

## 목록

- [xcode-spm/swift6-strict-concurrency-default.md](xcode-spm/swift6-strict-concurrency-default.md) — Swift 6 + strict concurrency 를 초기부터 켜도 SwiftUI placeholder 는 추가 표기 없이 무경고
- [xcode-spm/xcodeproj-empty-subdirs-not-tracked.md](xcode-spm/xcodeproj-empty-subdirs-not-tracked.md) — 빈 `xcshareddata/`·`project.xcworkspace/` 미추적 → share scheme 누락으로 다른 머신 빌드 깨질 수 있음
- [macos-sandbox/hardened-runtime-adhoc-sign-note.md](macos-sandbox/hardened-runtime-adhoc-sign-note.md) — `Disabling hardened runtime with ad-hoc codesigning` note 는 정상, Hardened Runtime ON 통과 조건 위반 아님
- [git-ci/gitignore-xcodeproj-pitfall.md](git-ci/gitignore-xcodeproj-pitfall.md) — `.gitignore` 의 `*.xcodeproj` 는 네이티브 Xcode 프로젝트 저장소에서 반드시 제거
- [swiftui/swiftui-table-row-hit-area-and-custom-layout.md](swiftui/swiftui-table-row-hit-area-and-custom-layout.md) — SwiftUI `TableColumn` 셀 modifier 는 행 전체 hit area 가 아니며, custom row 전환 시 컬럼 폭은 패널 폭 기반으로 계산
- [xcode-spm/pbxproj-gen-script-required-for-new-sources.md](xcode-spm/pbxproj-gen-script-required-for-new-sources.md) — 신규 `*.swift` 추가 후 `python3 scripts/gen_xcode_pbx.py` 안 돌리면 "cannot find ... in scope" 가 미등록을 가린다
- [xcode-spm/deriveddata-test-bundle-codesign-failure.md](xcode-spm/deriveddata-test-bundle-codesign-failure.md) — `build` 만 했는데 CodeSign 단계에서 `xctest` 번들이 깨져 실패하면 DerivedData 부터 비운다
- [swiftui/foreach-duplicate-url-id-when-symlink-meets-mounted-volume.md](swiftui/foreach-duplicate-url-id-when-symlink-meets-mounted-volume.md) — 심볼릭이 mounted volume 과 같은 URL 을 가지면 `ForEach` 가 한쪽만 렌더링해 행 번호가 뒤죽박죽. 합칠 때 id dedupe + 1..N 재번호.
- [swiftui/ismountedvolume-flag-always-false-dedup-mismatch.md](swiftui/ismountedvolume-flag-always-false-dedup-mismatch.md) — `isMountedVolume` 플래그는 항상 `false`라 신뢰 불가. 드라이브 제외는 `mountedVolumes.map(\.id)` 집합과 대조해야 `paneRows` dedup과 일치.
- [swiftui/select-all-must-exclude-volumes-via-url-set.md](swiftui/select-all-must-exclude-volumes-via-url-set.md) — 일괄 선택(복사·이동·삭제 포함)은 `volumeIDs` URL 집합으로 볼륨을 명시 제외해야 한다.
- [swiftui/onkeypress-consumed-by-parent-when-sheet-is-open.md](swiftui/onkeypress-consumed-by-parent-when-sheet-is-open.md) — sheet 열려 있어도 부모 `.onKeyPress` 가 키를 먼저 소비. `.ignored` 반환으로 sheet 에 전달.
- [xcode-spm/test-host-deriveddata-mismatch-with-custom-build-dir.md](xcode-spm/test-host-deriveddata-mismatch-with-custom-build-dir.md) — `CONFIGURATION_BUILD_DIR=dist` 사용 시 build·test 를 같은 `-derivedDataPath` 로 묶지 않으면 TEST_HOST 불일치.
- [xcode-spm/gen-pbxproj-literal-tab-vs-actual-tab.md](xcode-spm/gen-pbxproj-literal-tab-vs-actual-tab.md) — `gen_xcode_pbx.py` 에 리터럴 `\t` 와 실제 탭이 혼용됨. Edit 툴 매칭 실패 시 `repr()` 확인 후 Python 스크립트로 치환.
- [swiftui/onkeypress-action-closure-skips-function-keys.md](swiftui/onkeypress-action-closure-skips-function-keys.md) — `.onKeyPress(action:)` 클로저는 펑션 키(F1~F12)를 라우팅 안 함. `.onKeyPress(keys: [...])` 명시 등록 오버로드 사용.
- [swiftui/onkeypress-character-becomes-hangul-jamo-under-korean-ime.md](swiftui/onkeypress-character-becomes-hangul-jamo-under-korean-ime.md) — 한글 IME ON 시 modifier 동반에도 `press.key.character`가 자모(ㅣ/ㅏ…)로 변환. QWERTY 역매핑 헬퍼로 정규화 후 비교.
- [xcode-spm/gen-pbxproj-new-file-registration-checklist.md](xcode-spm/gen-pbxproj-new-file-registration-checklist.md) — `gen_xcode_pbx.py`는 자동 스캔이 아닌 하드코딩. 새 파일 추가 시 UID/BuildFile/FileReference/Group/Phase 5곳 일관 등록.
- [swift/print-stdout-not-captured-for-gui-app-use-nslog.md](swift/print-stdout-not-captured-for-gui-app-use-nslog.md) — GUI 앱에서 `print()`는 stdout 버퍼링으로 묻힐 수 있음. 임시 디버그 로그는 `NSLog` 사용.

## 메타 노트

- **키 바인딩은 단위 테스트로 잡히지 않는다.** 빌드·단위 테스트가 모두 통과해도 실제 키 입력이 `onKeyPress`까지 도달 안 할 수 있다. 새 단축키를 `done` 처리하기 전 **사용자가 직접 한 번 눌러 동작을 확인**하는 절차를 통과 조건에 포함시킬 것. (사례: F2 rename은 이번 F5/F6 작업 시 사용자가 처음 눌러보기 전까지 `done` 상태로 깨져 있었다.)
