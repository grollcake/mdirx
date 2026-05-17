import SwiftData

enum PersistenceBootstrap {
    static func makeEmptyContainer() throws -> ModelContainer {
        let schema = Schema([PathHistoryEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeAppContainer() throws -> ModelContainer {
        let schema = Schema([PathHistoryEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
