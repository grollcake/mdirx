import SwiftUI

@main
struct MdirXApp: App {
    init() {
        AppSettings.shared.load()
    }

    var body: some Scene {
        WindowGroup {
            DualPaneView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1000, height: 600)
    }
}
