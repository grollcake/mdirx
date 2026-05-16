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
        if let testRoot = ProcessInfo.processInfo.environment["MDIRX_TEST_ROOT"], !testRoot.isEmpty {
            let u = URL(fileURLWithPath: testRoot, isDirectory: true)
            left = PaneState(slot: .left, initialURL: u)
            right = PaneState(slot: .right, initialURL: u)
        } else {
            left = PaneState(slot: .left, initialURL: PaneRestore.url(for: .left) ?? home)
            right = PaneState(slot: .right, initialURL: PaneRestore.url(for: .right) ?? home)
        }
    }

    var current: PaneState {
        activePane == .left ? left : right
    }

    func toggleActive() {
        activePane = activePane == .left ? .right : .left
    }

    func moveSelectionInActivePane(delta: Int) {
        current.moveSelection(delta: delta)
    }

    func bootstrap() async {
        async let l: Void = left.load(via: fs)
        async let r: Void = right.load(via: fs)
        _ = await (l, r)
    }
}
