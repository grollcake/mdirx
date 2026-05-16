import SwiftData

enum PersistenceBootstrap {
    static func makeEmptyContainer() throws -> ModelContainer {
        let schema = Schema([])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
