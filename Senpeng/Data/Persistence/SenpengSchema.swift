import Foundation
import SwiftData

/// Version 1 of the on-device database layout.
///
/// When the layout changes in a later release, add a `SenpengSchemaV2` and a
/// migration stage in `SenpengMigrationPlan`, so users keep their saved trips.
/// Never change the models of a released version.
enum SenpengSchemaV1: VersionedSchema {

    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TripRecord.self]
    }
}

/// Describes how the database is upgraded between versions.
enum SenpengMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [SenpengSchemaV1.self]
    }

    /// No migrations yet; version 1 is the first release.
    static var stages: [MigrationStage] {
        []
    }
}

/// The trip model of the current schema version.
typealias TripRecord = SenpengSchemaV1.TripRecord
