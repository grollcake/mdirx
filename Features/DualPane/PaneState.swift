import AppKit
import Foundation

enum PaneSlot: String, Sendable, CaseIterable {
    case left
    case right
}

@MainActor
@Observable
final class PaneState {
    let slot: PaneSlot
    private(set) var currentURL: URL
    private(set) var entries: [DirectoryEntry] = []
    private(set) var mountedVolumes: [MountedVolume] = []
    var cursorID: URL?
    var selection: Set<URL> = []
    var error: String?
    var hiddenVisible: Bool = false

    var onPathVisited: ((URL) -> Void)?

    var addressEditing = false
    var addressDraft = ""
    var addressError: String? = nil
    var addressFocusToken: Int = 0

    // popover 히스토리 리스트 ↓키 탐색용
    var addressListItems: AddressListItems = .empty
    var addressListFocusIndex: Int? = nil   // nil = TextField focus, ≥0 = list focus

    var addressListFlat: [URL] {
        addressListItems.frequent + addressListItems.recent
    }

    init(slot: PaneSlot, initialURL: URL) {
        self.slot = slot
        self.currentURL = initialURL
        persistURL()
    }

    var selectableEntries: [DirectoryEntry] {
        let volumeIDs = Set(mountedVolumes.map(\.id))
        return entries.filter { !$0.isParentLink && !$0.isMountedVolume && !volumeIDs.contains($0.id) }
    }

    var selectableIDs: [URL] { selectableEntries.map(\.id) }

    var fileOnlyIDs: [URL] {
        let volumeIDs = Set(mountedVolumes.map(\.id))
        return entries
            .filter { !$0.isParentLink && !$0.isMountedVolume && !$0.isDirectory && !volumeIDs.contains($0.id) }
            .map(\.id)
    }

    func load(via fs: FileSystemActor) async {
        do {
            let list = try await fs.listDirectory(at: currentURL, includeHidden: hiddenVisible)
            let volumes = VolumeService.mountedVolumes()
            entries = list
            mountedVolumes = volumes
            error = nil
            if let cur = cursorID, paneRows.contains(where: { $0.id == cur }) {
                // keep cursor
            } else {
                cursorID = list.first(where: { !$0.isParentLink && !$0.isMountedVolume })?.id
                    ?? list.first?.id
                    ?? volumes.first?.id
            }
            let alive = Set(list.map(\.id)).union(Set(volumes.map(\.id)))
            selection.formIntersection(alive)
            persistURL()
        } catch {
            entries = []
            mountedVolumes = []
            selection.removeAll()
            self.error = error.localizedDescription
        }
    }

    private func jumpToDirectory(_ url: URL, via fs: FileSystemActor) async {
        let priorPath = currentURL.standardizedFileURL.path
        currentURL = url.resolvingSymlinksInPath()
        cursorID = nil
        selection.removeAll()
        await load(via: fs)
        guard error == nil, priorPath != currentURL.standardizedFileURL.path else { return }
        onPathVisited?(currentURL)
    }

    func enter(via fs: FileSystemActor) async {
        guard let sel = cursorID,
              let entry = entries.first(where: { $0.id == sel })
        else {
            if let volume = mountedVolumes.first(where: { $0.id == cursorID }) {
                await jumpToDirectory(volume.id, via: fs)
            }
            return
        }

        if entry.isParentLink {
            await jumpToDirectory(entry.url, via: fs)
            return
        }

        guard entry.isDirectory else { return }
        await jumpToDirectory(entry.url, via: fs)
    }

    func navigate(to url: URL, via fs: FileSystemActor) async {
        await jumpToDirectory(url, via: fs)
    }

    func ascend(via fs: FileSystemActor) async {
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        await jumpToDirectory(parent, via: fs)
    }

    func toggleHidden(via fs: FileSystemActor) async {
        hiddenVisible.toggle()
        await load(via: fs)
    }

    enum PrimaryMouseAction: Equatable {
        case noSelection
        case ascend
        case navigateMountedVolume(URL)
        case enterDirectory
        case openFile(URL)
    }

    static func inspectPrimaryMouseDoubleClick(cursorID: URL?, entries: [DirectoryEntry]) -> PrimaryMouseAction {
        guard let id = cursorID,
              let entry = entries.first(where: { $0.id == id }) else {
            return .noSelection
        }
        if entry.isParentLink { return .ascend }
        if entry.isMountedVolume { return .navigateMountedVolume(entry.url) }
        if entry.isDirectory { return .enterDirectory }
        return .openFile(entry.url)
    }

    func handleDoubleClick(via fs: FileSystemActor) async {
        await handleDoubleClick(via: fs, openFile: Self.openFileForPrimaryMouseAction)
    }

    func handleDoubleClick(via fs: FileSystemActor, openFile: (URL) -> Bool) async {
        if let volume = mountedVolumes.first(where: { $0.id == cursorID }) {
            await jumpToDirectory(volume.id, via: fs)
            return
        }

        switch Self.inspectPrimaryMouseDoubleClick(cursorID: cursorID, entries: entries) {
        case .noSelection:
            return
        case .ascend:
            await ascend(via: fs)
        case let .navigateMountedVolume(volumeURL):
            await jumpToDirectory(volumeURL, via: fs)
        case .enterDirectory:
            await enter(via: fs)
        case let .openFile(url):
            _ = openFile(url)
        }
    }

    private static func openFileForPrimaryMouseAction(_ url: URL) -> Bool {
        let env = ProcessInfo.processInfo.environment
        if let logPath = env["MDIRX_TEST_OPEN_LOG"], !logPath.isEmpty {
            let logURL = URL(fileURLWithPath: logPath)
            guard let data = "\(url.standardizedFileURL.path)\n".data(using: .utf8) else {
                return false
            }
            if FileManager.default.fileExists(atPath: logPath),
               let handle = try? FileHandle(forWritingTo: logURL) {
                do {
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                    return true
                } catch {
                    try? handle.close()
                    return false
                }
            }
            do {
                try data.write(to: logURL, options: .atomic)
                return true
            } catch {
                return false
            }
        }
        return NSWorkspace.shared.open(url)
    }

    // MARK: - Cursor / selection ops

    func moveSelection(delta: Int) {
        let rows = paneRows
        guard !rows.isEmpty else { return }
        if cursorID == nil {
            cursorID = rows.first?.id
            return
        }
        guard let idx = rows.firstIndex(where: { $0.id == cursorID }) else {
            cursorID = rows.first?.id
            return
        }
        let j = idx + delta
        guard j >= 0, j < rows.count else { return }
        cursorID = rows[j].id
    }

    func operationItemURLs() -> [URL] {
        let allowed = Set(selectableIDs)
        let selected = selection.filter { allowed.contains($0) }
        if !selected.isEmpty {
            return selectableEntries
                .map(\.url)
                .filter { selected.contains($0) }
        }
        guard let cur = cursorID, allowed.contains(cur) else { return [] }
        return entries.first(where: { $0.id == cur }).map { [$0.url] } ?? []
    }

    func toggleAtCursor() {
        guard let cur = cursorID, selectableIDs.contains(cur) else { return }
        if selection.contains(cur) {
            selection.remove(cur)
        } else {
            selection.insert(cur)
        }
    }

    func spacePress() {
        toggleAtCursor()
        moveSelection(delta: 1)
    }

    func shiftDownPress() { spacePress() }

    func shiftUpPress() {
        toggleAtCursor()
        moveSelection(delta: -1)
    }

    private enum SelectAllPhase { case none, files, filesAndFolders }
    @ObservationIgnored private var selectAllPhase: SelectAllPhase = .none

    func selectAllToggle() {
        switch selectAllPhase {
        case .none:
            selectAllPhase = .files
            selection = Set(fileOnlyIDs)
        case .files:
            selectAllPhase = .filesAndFolders
            selection = Set(selectableIDs)
        case .filesAndFolders:
            selectAllPhase = .none
            selection = []
        }
    }

    func clearSelection() {
        selection.removeAll()
    }

    func extendRange(to clickedID: URL) {
        let ids = selectableIDs
        guard let from = cursorID,
              let i = ids.firstIndex(of: from),
              let j = ids.firstIndex(of: clickedID) else {
            cursorID = clickedID
            return
        }
        let lo = min(i, j), hi = max(i, j)
        for k in lo...hi {
            selection.insert(ids[k])
        }
        cursorID = clickedID
    }

    func toggleSingle(at clickedID: URL) {
        cursorID = clickedID
        guard selectableIDs.contains(clickedID) else { return }
        if selection.contains(clickedID) {
            selection.remove(clickedID)
        } else {
            selection.insert(clickedID)
        }
    }

    private func persistURL() {
        UserDefaults.standard.set(currentURL, forKey: "pane.\(slot.rawValue).lastURL")
    }

    // MARK: - Address bar

    func beginAddressEditing(items: AddressListItems = .empty) {
        addressEditing = true
        addressDraft = currentURL.path
        addressError = nil
        addressFocusToken &+= 1
        addressListItems = items
        addressListFocusIndex = nil
    }

    func cancelAddressEditing() {
        addressEditing = false
        addressDraft = ""
        addressError = nil
        addressListItems = .empty
        addressListFocusIndex = nil
    }

    func submitAddressDraft(via fs: FileSystemActor) async {
        switch AddressPathValidator.expandAndNormalize(addressDraft) {
        case .failure(let err):
            addressError = err.userMessage
        case .success(let url):
            addressError = nil
            await navigate(to: url, via: fs)
            cancelAddressEditing()
        }
    }

    /// TextField에 포커스가 있을 때 ↓키 → 리스트 첫 항목.
    /// 리스트가 비어 있으면 false 반환(호출자가 키를 처리하지 않음).
    @discardableResult
    func focusListFirst() -> Bool {
        guard !addressListFlat.isEmpty else { return false }
        addressListFocusIndex = 0
        return true
    }

    func focusListNext() {
        let last = addressListFlat.count - 1
        guard last >= 0 else { return }
        let cur = addressListFocusIndex ?? -1
        addressListFocusIndex = min(last, cur + 1)
    }

    /// 리스트 첫 항목에서 ↑ → TextField 복귀(nil). 그 외엔 한 칸 위로.
    func focusListPrevious() {
        guard let cur = addressListFocusIndex else { return }
        addressListFocusIndex = cur <= 0 ? nil : cur - 1
    }

    func focusTextField() {
        addressListFocusIndex = nil
    }

    /// 현재 highlight된 리스트 항목 URL. TextField focus거나 인덱스가 범위 밖이면 nil.
    var addressListFocusedURL: URL? {
        guard let idx = addressListFocusIndex,
              addressListFlat.indices.contains(idx) else { return nil }
        return addressListFlat[idx]
    }

    // MARK: - Name Editing

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
        if s.isEmpty { editingError = nil; return }
        if s.contains("/") || s.contains("\0") {
            editingError = "사용할 수 없는 문자: / 또는 NUL"; return
        }
        if s == "." || s == ".." {
            editingError = "이 이름은 사용할 수 없습니다"; return
        }
        let dupe = entries.contains { e in
            let existing = e.displayName + (e.ext.isEmpty ? "" : ".\(e.ext)")
            if case .rename(let u) = editing, e.url == u { return false }
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

enum NameEditingMode: Equatable, Identifiable {
    case rename(URL)
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

struct AddressListItems: Equatable {
    var frequent: [URL]
    var recent: [URL]

    static let empty = AddressListItems(frequent: [], recent: [])
}

enum PaneRestore {
    @MainActor
    static func url(for slot: PaneSlot) -> URL? {
        guard let u = UserDefaults.standard.url(forKey: "pane.\(slot.rawValue).lastURL") else {
            return nil
        }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        return u
    }
}
