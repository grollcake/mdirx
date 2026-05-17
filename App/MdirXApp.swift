import SwiftData
import SwiftUI

@main
struct MdirXApp: App {
    private let modelContainer: ModelContainer

    init() {
        AppSettings.shared.load()
        do {
            modelContainer = try PersistenceBootstrap.makeAppContainer()
        } catch {
            fatalError("SwiftData ModelContainer failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            DualPaneView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 1000, height: 600)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))
    }
}
