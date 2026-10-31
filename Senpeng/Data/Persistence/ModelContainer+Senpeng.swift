import Foundation
import SwiftData

extension ModelContainer {

    /// Creates the app's on-device database.
    ///
    /// Create it once (in the app's dependency container) and share it.
    ///
    /// - Parameter inMemory: `true` for tests and previews: nothing is written to disk.
    /// - Returns: The database container.
    /// - Throws: An error if the database can't be opened.
    static func makeSenpengContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SenpengSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            // Trips stay on this device only; no iCloud sync (see privacy rules).
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: SenpengMigrationPlan.self,
            configurations: configuration
        )
    }
}
