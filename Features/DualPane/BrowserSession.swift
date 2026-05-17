import Foundation

enum ActivePane: Equatable {
    case left
    case right
}

@MainActor
@Observable
final class BrowserSession {
    let left: PaneState
    let right: PaneState
    var activePane: ActivePane = .left
    let fs = FileSystemActor()

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let env = ProcessInfo.processInfo.environment
        if let initialLeft = Self.directoryURL(from: env["MDIRX_INITIAL_LEFT_URL"]),
           let initialRight = Self.directoryURL(from: env["MDIRX_INITIAL_RIGHT_URL"]) {
            left = PaneState(slot: .left, initialURL: initialLeft)
            right = PaneState(slot: .right, initialURL: initialRight)
        } else if let testRoot = env["MDIRX_TEST_ROOT"], !testRoot.isEmpty {
            let u = URL(fileURLWithPath: testRoot, isDirectory: true)
            left = PaneState(slot: .left, initialURL: u)
            right = PaneState(slot: .right, initialURL: u)
        } else {
            left = PaneState(slot: .left, initialURL: PaneRestore.url(for: .left) ?? home)
            right = PaneState(slot: .right, initialURL: PaneRestore.url(for: .right) ?? home)
        }
    }

    private static func directoryURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: path, isDirectory: true)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        return url
    }

    var current: PaneState {
        activePane == .left ? left : right
    }

    var other: PaneState {
        activePane == .left ? right : left
    }

    func toggleActive() {
        activePane = activePane == .left ? .right : .left
    }

    func moveSelectionInActivePane(delta: Int) {
        current.moveSelection(delta: delta)
    }

    func syncLeftToRight() async {
        await right.navigate(to: left.currentURL, via: fs)
    }

    func syncRightToLeft() async {
        await left.navigate(to: right.currentURL, via: fs)
    }

    func copySelectionToOtherPane() async {
        await transferSelectionToOtherPane(move: false)
    }

    func moveSelectionToOtherPane() async {
        await transferSelectionToOtherPane(move: true)
    }

    private func transferSelectionToOtherPane(move: Bool) async {
        let source = current
        let destination = other
        let urls = source.operationItemURLs()
        guard !urls.isEmpty else { return }

        do {
            if move {
                _ = try await fs.moveItems(urls, to: destination.currentURL)
            } else {
                _ = try await fs.copyItems(urls, to: destination.currentURL)
            }
            source.error = nil
            destination.error = nil
            async let sourceReload: Void = source.load(via: fs)
            async let destinationReload: Void = destination.load(via: fs)
            _ = await (sourceReload, destinationReload)
        } catch {
            source.error = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }

    func bootstrap() async {
        async let l: Void = left.load(via: fs)
        async let r: Void = right.load(via: fs)
        _ = await (l, r)
    }
}
