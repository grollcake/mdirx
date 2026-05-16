# 이름변경·새 폴더·빈 파일 만들기

## 사용자 요구 (정제)

- **정제:** 활성 패널의 현재 디렉터리에서 세 가지 기본 파일 매니저 작업을 키보드로 수행한다. ① **F2** = cursor 행의 이름변경(전체 파일명 편집, NexusFile 식), ② **⌥K (Alt+K)** = 새 폴더 만들기, ③ **⌃N (Ctrl+N)** = 빈 파일 만들기. 세 동작 모두 **모달 sheet** 로 텍스트 입력을 받고, **Esc=취소·Enter=확정**, 검증 실패(빈 이름·중복·잘못된 문자)는 모달 안에서 빨강 메시지로 표시하며 확정 버튼을 비활성화한다. 성공 후 패널을 reload 하고 cursor 를 새/변경된 항목 위로 옮긴다. `..` 와 마운트 볼륨 행 위에서는 세 동작 모두 무동작.
- **원문 뉘앙스:** "이름변경과 새폴더 하자. 이름변경은 F2, 새폴더는 ALT+K, 빈 파일 만들기는 CTRL+N" + "all default" (12개 결정 표 모두 권장안).
- **의도 보존:** 이번 계획은 **단일 항목 단발 동작**만. 다중 일괄 이름변경(`⇧⌥R` 고급 이름변경)·복사·이동·삭제는 별도 후속.

## 개요

`PaneState` 에 모달 입력 상태(`editing: NameEditingMode`, `editingDraft: String`, `editingError: String?`) 를 추가하고, 입력 의뢰 메서드 3종(`requestRename`/`requestNewFolder`/`requestNewFile`) 과 확정 메서드 3종(`commitRename(newName:)`/`commitNewFolder(name:)`/`commitNewFile(name:)`) 을 둔다. `FileSystemActor` 에 동일한 3종의 IO 메서드를 추가한다. `DualPaneView` 가 `.onKeyPress` 로 키 3종을 가로채 의뢰 메서드를 호출하고, `PaneColumnView` 가 `.sheet(item: editing)` 으로 신규 `NameEditModal` 을 띄운다. 모달은 TextField + 인라인 빨강 에러 + 확인·취소 버튼만의 간단한 형태.

## 요구사항

### 키 매핑
| 키 | 동작 | 활성 조건 |
|---|---|---|
| `F2` | cursor 행 이름변경 모달 | cursor 가 일반 파일·일반 폴더일 때만(파일 시스템 항목). `..`·볼륨·cursor 없음 → 무동작 |
| `⌥K` (Option+K) | 새 폴더 모달 | 활성 패널의 `currentURL` 이 쓰기 가능한 디렉터리일 때 |
| `⌃N` (Control+N) | 빈 파일 모달 | 활성 패널의 `currentURL` 이 쓰기 가능한 디렉터리일 때 |

- 세 키 모두 모달 sheet 가 떠 있는 상태에서는 OS 의 sheet 우선이라 자연 차단됨.
- 키맵에 macOS 보조 바인딩 동시 추가는 본 계획 범위 밖(NexusFile 호환 우선).

### 모달 sheet — `NameEditModal`
- **레이아웃** (한 컬럼, 320 pt 폭, 자동 높이):
  - 상단 `Text(title)` — `.system(size: 14, weight: .semibold)`. 모드별 타이틀:
    - rename: `이름 변경`
    - newFolder: `새 폴더`
    - newFile: `빈 파일 만들기`
  - 본문 `TextField("", text: $draft)` — autofocus, monospaced `.system(size: 13)`. 위·아래 padding 8 pt.
  - 인라인 에러(있을 때만): 빨강 `.foregroundStyle(.red)` `Text(error)` `.system(size: 12)`. TextField 바로 아래.
  - 하단 `HStack { Spacer; Button("취소") { cancel() }; Button("확인") { confirm() }.buttonStyle(.borderedProminent).disabled(error != nil || draft.isEmpty) }`. 오른쪽 정렬, padding 12 pt.
- **autofocus**: 첫 표시 시 TextField 가 firstResponder. iOS 17 / macOS 14+ 의 `.focused($focus, equals: .field)` 로 보장.
- **rename 모드의 draft 초기값**: cursor 행의 `displayName + (ext.isEmpty ? "" : ".\(ext)")` — NexusFile 식 전체 파일명. 텍스트 필드 전체 선택 상태로 시작(전체 교체 편의).
- **newFolder/newFile draft 초기값**: 빈 문자열.
- **키**: Esc → cancel, Enter → confirm (단 검증 통과 시).
- **모달 외부 클릭 / 윈도우 포커스 변경**: 모달 유지(자동 닫힘 없음).

### 검증 (모달 안에서 즉시)
- `draft.isEmpty` → 에러 `"이름을 입력하세요"`.
- `draft.contains("/")` 또는 `draft.contains("\0")` → 에러 `"사용할 수 없는 문자: / 또는 NUL"`.
- `draft == "." || draft == ".."` → 에러 `"이 이름은 사용할 수 없습니다"`.
- 중복: 활성 패널 `entries` 중 `displayName + ext` 가 draft 와 같은 항목이 있고(rename 모드에서는 자기 자신 제외) → 에러 `"같은 이름의 항목이 이미 있습니다"`.
- 검증 통과 시: error = nil, 확인 버튼 활성.
- draft 변경 시 검증 매번 재계산(`onChange(of: draft)`).

### 확정 — 동작
- **rename**: `FileSystemActor.rename(at: cursor.url, to: draft)` → 결과 URL 반환받아 `pane.cursorID = result`, `await pane.load()`.
- **newFolder**: `FileSystemActor.createDirectory(at: pane.currentURL, name: draft)` → `pane.cursorID = result`, `await pane.load()`.
- **newFile**: `FileSystemActor.createEmptyFile(at: pane.currentURL, name: draft)` → `pane.cursorID = result`, `await pane.load()`.
- 성공 후 모달 닫힘 (`editing = .none`).
- 실패(권한·디스크 풀·동시 충돌 등): 모달 **유지**, `editingError = error.localizedDescription`, 확인 버튼 비활성. 사용자가 다시 입력하거나 취소.

### 효과
- **selection 정합성**: rename 결과 새 URL 이 기존 selection 에 있던 자기 자신을 대체. 코드:
  ```
  if selection.remove(oldURL) != nil { selection.insert(newURL) }
  ```
- **cursor**: 위 세 동작 모두 결과 항목으로 이동.
- **error 인라인 표시**: 모달이 떠 있는 동안만. 모달 닫히면 `editingError = nil`.

### 비범위
- 다중 일괄 이름변경 / 정규식 변환 — `⇧⌥R` 고급 이름변경 별도 계획.
- 새 폴더 생성 후 즉시 이름변경 모드 진입(Finder 식).
- 템플릿 기반 파일 생성(빈 텍스트 외 형식).
- 잘라내기·복사·붙여넣기 — 후속.
- 휴지통 이동·삭제 — 후속.
- Undo / Redo.
- 마우스 우클릭 컨텍스트 메뉴.

### 성능·제약
- macOS 15+, Swift 6 strict concurrency 0 warning 유지.
- 모달 입력은 `@MainActor`, IO 는 `FileSystemActor` 안에서만.
- `FileSystemActor` 새 메서드는 모두 throw — UI 가 do/catch 로 처리.

## 수도 코드

```
// Features/DualPane/PaneState.swift  (확장)
enum NameEditingMode: Equatable, Identifiable {
    case rename(URL)          // 대상 URL
    case newFolder
    case newFile
    var id: String {
        switch self {
        case .rename(let u): return "rename:\(u.path)"
        case .newFolder:     return "newFolder"
        case .newFile:       return "newFile"
        }
    }
}

@Observable @MainActor final class PaneState {
    // ...
    var editing: NameEditingMode? = nil
    var editingDraft: String = ""
    var editingError: String? = nil

    func requestRename() {
        guard let id = cursorID,
              let e = entries.first(where: { $0.id == id }),
              !e.isParentLink, !e.isMountedVolume else { return }
        editing = .rename(e.url)
        editingDraft = e.displayName + (e.ext.isEmpty ? "" : ".\(e.ext)")
        editingError = nil
    }

    func requestNewFolder() {
        editing = .newFolder
        editingDraft = ""
        editingError = nil
    }

    func requestNewFile() {
        editing = .newFile
        editingDraft = ""
        editingError = nil
    }

    func validateDraft() {
        let s = editingDraft
        if s.isEmpty { editingError = "이름을 입력하세요"; return }
        if s.contains("/") || s.contains("\0") {
            editingError = "사용할 수 없는 문자: / 또는 NUL"; return
        }
        if s == "." || s == ".." {
            editingError = "이 이름은 사용할 수 없습니다"; return
        }
        let dupe = entries.contains { e in
            let existing = e.displayName + (e.ext.isEmpty ? "" : ".\(e.ext)")
            if case .rename(let u) = editing, e.url == u { return false }   // 자기 자신 제외
            return existing == s
        }
        if dupe { editingError = "같은 이름의 항목이 이미 있습니다"; return }
        editingError = nil
    }

    func commit(via fs: FileSystemActor) async {
        validateDraft()
        guard editingError == nil, let mode = editing else { return }
        do {
            let resultURL: URL
            switch mode {
            case .rename(let target):
                resultURL = try await fs.rename(at: target, to: editingDraft)
                if selection.remove(target) != nil { selection.insert(resultURL) }
            case .newFolder:
                resultURL = try await fs.createDirectory(at: currentURL, name: editingDraft)
            case .newFile:
                resultURL = try await fs.createEmptyFile(at: currentURL, name: editingDraft)
            }
            editing = nil
            editingDraft = ""
            editingError = nil
            await load(via: fs)
            cursorID = resultURL
        } catch {
            editingError = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
        }
    }

    func cancelEditing() {
        editing = nil
        editingDraft = ""
        editingError = nil
    }
}

// Core/FileSystem/FileSystemActor.swift  (확장)
actor FileSystemActor {
    func rename(at url: URL, to newName: String) async throws -> URL {
        let dest = url.deletingLastPathComponent().appendingPathComponent(newName)
        try FileManager.default.moveItem(at: url, to: dest)
        return dest
    }
    func createDirectory(at parent: URL, name: String) async throws -> URL {
        let dest = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: false)
        return dest
    }
    func createEmptyFile(at parent: URL, name: String) async throws -> URL {
        let dest = parent.appendingPathComponent(name, isDirectory: false)
        guard FileManager.default.createFile(atPath: dest.path, contents: nil) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError,
                          userInfo: [NSLocalizedDescriptionKey: "파일 생성 실패"])
        }
        return dest
    }
}

// Features/DualPane/DualPaneView.swift  (키 3종 + sheet)
.onKeyPress(.init("F2")) {                                       // F2
    session.current.requestRename(); return .handled
}
.onKeyPress("k", modifiers: .option) {
    session.current.requestNewFolder(); return .handled
}
.onKeyPress("n", modifiers: .control) {
    session.current.requestNewFile(); return .handled
}
// PaneColumnView 안에서
.sheet(item: $state.editing) { _ in
    NameEditModal(state: state, fs: session.fs)
}

// Features/Pane/NameEditModal.swift  (신규)
struct NameEditModal: View {
    @Bindable var state: PaneState
    let fs: FileSystemActor
    @FocusState private var focus: Bool

    var title: String {
        switch state.editing {
        case .rename:     "이름 변경"
        case .newFolder:  "새 폴더"
        case .newFile:    "빈 파일 만들기"
        case .none:       ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .semibold))
            TextField("", text: $state.editingDraft)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .focused($focus)
                .onSubmit { Task { await state.commit(via: fs) } }
                .onChange(of: state.editingDraft) { _, _ in state.validateDraft() }
            if let err = state.editingError {
                Text(err).foregroundStyle(.red).font(.system(size: 12))
            }
            HStack {
                Spacer()
                Button("취소") { state.cancelEditing() }.keyboardShortcut(.escape)
                Button("확인") { Task { await state.commit(via: fs) } }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(state.editingError != nil || state.editingDraft.isEmpty)
            }
        }
        .padding(12)
        .frame(width: 320)
        .task { focus = true; state.validateDraft() }
        .accessibilityIdentifier("pane.\(state.slot.rawValue).edit.modal")
    }
}
```

## 아키텍처

- **수정 파일**
  - `Features/DualPane/PaneState.swift` — `NameEditingMode` enum, `editing`/`editingDraft`/`editingError` 필드, 6개 메서드.
  - `Features/DualPane/DualPaneView.swift` — `.onKeyPress` 3종 추가.
  - `Features/Pane/PaneColumnView.swift` — `.sheet(item: $state.editing)` 부착.
  - `Core/FileSystem/FileSystemActor.swift` — 3 메서드 추가(`rename`/`createDirectory`/`createEmptyFile`).
- **신규 파일**
  - `Features/Pane/NameEditModal.swift` — §S 사양대로.
- **데이터 흐름**: 키 → `requestX` → `editing` 설정 → sheet 자동 표시 → TextField → `validateDraft` → 확인 클릭 → `commit(via:)` → `FileSystemActor` → 성공 시 `load`+cursor 이동·sheet 닫힘 / 실패 시 sheet 유지+에러 표기.
- **외부 의존성**: `FileManager` 만.

## 통과 조건 — 구체·측정 가능

### A. 빌드·테스트
- [ ] `xcodebuild build` 0 error / 0 warning.
- [ ] `xcodebuild test` — 신규 + 기존 모두 통과.

### B. 파일 존재
- [ ] `Features/Pane/NameEditModal.swift` 존재.
- [ ] `Features/DualPane/PaneState.swift` 에 `enum NameEditingMode` 와 `case rename` 문자열 모두 존재.
- [ ] `Core/FileSystem/FileSystemActor.swift` 에 `func rename(at:`, `func createDirectory(at:`, `func createEmptyFile(at:` 세 시그니처 모두 grep 매치.

### C. 키 바인딩
- [ ] `Features/DualPane/DualPaneView.swift` 에 `.onKeyPress(.init("F2"))` (또는 동등한 F2 처리), `modifiers: .option` 의 `"k"`, `modifiers: .control` 의 `"n"` 세 호출이 각각 1건 이상.

### D. 단위 테스트 — `Tests/UnitTests/NameEditTests.swift`
- [ ] 빈 디렉터리에서 `requestNewFolder()` → `editing == .newFolder`, `editingDraft == ""`, `editingError == "이름을 입력하세요"` (`validateDraft` 호출 후).
- [ ] `editingDraft = "foo/bar"` 후 validate → `editingError == "사용할 수 없는 문자: / 또는 NUL"`.
- [ ] `editingDraft = ".."` → `"이 이름은 사용할 수 없습니다"`.
- [ ] 사전에 같은 이름 항목이 있을 때 → `"같은 이름의 항목이 이미 있습니다"`.
- [ ] `cancelEditing()` → 모든 필드 초기화.
- [ ] `requestRename()` 호출 시 cursor 가 `..` → `editing == nil` (무동작).
- [ ] rename 모드에서 자기 자신 이름과 같은 draft → 중복 에러 없음(자기 자신 제외).

### E. 단위 테스트 — `Tests/UnitTests/FileSystemActorWriteTests.swift`
- [ ] `createDirectory(at: tmp, name: "alpha")` → 실제 디렉터리 생성됨, 반환 URL 의 lastPathComponent == `"alpha"`.
- [ ] 같은 이름 두 번 호출 → 두 번째는 throw.
- [ ] `createEmptyFile(at: tmp, name: "note.md")` → 파일 존재, 사이즈 0.
- [ ] `rename(at: tmp/old.txt, to: "new.txt")` → 결과 URL 의 이름이 `new.txt`, old 는 더 이상 존재하지 않음.

### F. UI 테스트 — `Tests/UITests/RenameNewFolderNewFileTests.swift`
- 테스트용 임시 디렉터리를 `launchEnvironment` 로 주입.
- [ ] **새 폴더**: `⌥K` 키 입력 → 모달 sheet 가 보임(`pane.left.edit.modal` 또는 `right`). 타이틀 `"새 폴더"` 텍스트 보임. `pane_test_dir` 라고 입력하고 `Enter` → 모달 닫힘, 리스트에 `pane_test_dir` 행 등장 + 그 행이 cursor.
- [ ] **새 폴더 — 빈 이름**: `⌥K` → 즉시 모달 안에 `"이름을 입력하세요"` 빨강 텍스트 + 확인 버튼 비활성.
- [ ] **새 폴더 — 중복**: `⌥K` → `pane_test_dir` (방금 만든) 입력 → 빨강 `"같은 이름의 항목이 이미 있습니다"` + 확인 비활성.
- [ ] **빈 파일**: `⌃N` → 모달 타이틀 `"빈 파일 만들기"`. `note.md` 입력 → 확정 후 행 등장 + cursor 이동.
- [ ] **이름변경**: cursor 가 `note.md` 일 때 `F2` → 모달 타이틀 `"이름 변경"`, 텍스트필드에 `note.md` 가 채워짐. 텍스트필드는 firstResponder. `note2.md` 로 변경 후 `Enter` → 모달 닫힘, 행 텍스트가 `note2.md`, cursor 가 그 행.
- [ ] **이름변경 — `..` 위에서**: cursor 를 `..` 로 이동 후 `F2` → 모달 안 뜸.
- [ ] **Esc 취소**: 모달 떠 있는 상태에서 `Esc` → 모달 닫힘, 리스트 변화 없음.

### G. 수동 검증 항목
- [ ] 점 폴더 생성: `⌥K` → `.dotfolder` 입력 → 성공. 히든 토글 OFF 일 때는 안 보이고 ON 일 때만 보임.
- [ ] 권한 거부 디렉터리에서 `⌥K` → `read-only-dir` 안에서는 모달은 뜨지만 확정 시 실패 메시지 인라인.
- [ ] 사용자 OK 후 본 문서·파일명을 `done` 으로.

## 구현 체크리스트

- [ ] `Features/Pane/NameEditModal.swift` 신규
- [ ] `Features/DualPane/PaneState.swift` — `NameEditingMode` enum + 필드 3개 + 메서드 6개
- [ ] `Features/DualPane/DualPaneView.swift` — `F2`/`⌥K`/`⌃N` `.onKeyPress` 3종
- [ ] `Features/Pane/PaneColumnView.swift` — `.sheet(item: $state.editing)` 부착
- [ ] `Core/FileSystem/FileSystemActor.swift` — `rename`/`createDirectory`/`createEmptyFile` 3종
- [ ] `Tests/UnitTests/NameEditTests.swift`
- [ ] `Tests/UnitTests/FileSystemActorWriteTests.swift`
- [ ] `Tests/UITests/RenameNewFolderNewFileTests.swift`
- [ ] accessibility identifiers: `pane.<slot>.edit.modal`, 모달 내부 TextField·확인·취소 버튼
- [ ] `MdirX.xcodeproj` 신규 소스 반영 (`scripts/gen_xcode_pbx.py`)
- [ ] [`PLAN.md`](../PLAN.md) §3 키맵에 행 추가:
  - `이름 변경 | F2 | F2 | —`
  - `새 폴더 | F7 | ⌥K | F7 보조` (NexusFile 의 F7 은 보조 자리, 본 계획 기본은 ⌥K)
  - `빈 파일 만들기 | — | ⌃N | —` (신규)
- [ ] `README.md` 상태 줄 갱신
- [ ] `.plan/STATUS.md` 행 추가 → 완료 시 갱신
- [ ] 커밋: `feat(pane): rename / new folder / new file (F2 / ⌥K / ⌃N)`

## 테스트 케이스

- **정상**
  - 빈 디렉터리에서 `⌥K` `alpha` Enter → `alpha/` 생성, cursor 그 위.
  - `⌃N` `note.md` Enter → 파일 0바이트 생성.
  - cursor 가 `note.md` 일 때 `F2` 로 `note2.md` 로 변경 → URL 갱신, 행 표시 텍스트 변경.
  - selection 에 `note.md` 가 들어 있던 상태에서 rename → selection 자동으로 `note2.md` 로 교체.
- **엣지**
  - 점 파일·점 폴더 생성 허용.
  - 매우 긴 이름(255 byte 한도 근처): 시스템 한도 도달 시 인라인 에러로 표시.
  - 동시에 외부에서 같은 이름 파일이 생성됨 → 검증은 통과했으나 IO 시점에 충돌 → 모달 유지 + IO 에러 인라인.
- **에러 / 미지원**
  - 권한 없는 디렉터리에서 새 폴더/파일 시도 → `FileManager` throw → 모달 인라인 에러.
  - `/` 포함 입력 → 검증 차단(IO 도달 전).
  - rename 대상이 모달 도중 외부에서 삭제됨 → IO throw → 모달 인라인.

## 디자인 결정 (default 채택)

| # | 결정 | 메모 |
|---|---|---|
| 1 | **모달 sheet 통일** | 세 동작 동일 UI 패턴 |
| 2 | **cursor 행만 이름변경** | selection 무시 |
| 3 | **이름 전체 편집(displayName+ext)** | NexusFile 식 |
| 4 | **`..`·볼륨 위에서 세 동작 무동작** | requestX 가 guard 로 차단 |
| 5 | **모달 안 인라인 빨강 + 확인 비활성** | 디버그 빠른 피드백 |
| 6 | **점 파일·점 폴더 허용** | 차단 없음 |
| 7 | **성공 직후 cursor 가 새 항목으로** | 사용 흐름 자연 |
| 8 | **selection 자동 갱신(rename 시)** | URL 변경 추적 |
| 9 | **Esc 취소 / Enter 확정** | 키보드 표준 |
| 10 | **확장자 입력 자유** | 드롭다운 없음 |
| 11 | **실패 시 모달 유지** | 재입력 가능 |
| 12 | **`⌥K` / `⌃N` 단독 바인딩** | macOS 보조 미바인딩(이번 범위 밖) |

---

**상태:** `todo` — 사용자 검토·OK 후 `doing` 으로 전이.
