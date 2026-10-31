import Foundation
import os
import SwiftData

/// The real `TripRepository`, which stores trips in the on-device SwiftData database.
///
/// It's a model actor, so all database work runs off the main thread,
/// one operation at a time, and the UI stays smooth.
@ModelActor
actor LiveTripRepository: TripRepository {

    func allTrips() throws(PersistenceError) -> [Trip] {
        let descriptor = FetchDescriptor<TripRecord>(
            sortBy: [SortDescriptor(\.scheduledDeparture, order: .reverse)]
        )
        return try fetch(descriptor).map { record throws(PersistenceError) in
            try record.toTrip()
        }
    }

    func trip(id: UUID) throws(PersistenceError) -> Trip? {
        try record(id: id)?.toTrip()
    }

    func save(_ trip: Trip) throws(PersistenceError) {
        if let existing = try record(id: trip.id) {
            existing.update(from: trip)
        } else {
            modelContext.insert(TripRecord(trip: trip))
        }
        try saveContext()
    }

    func delete(id: UUID) throws(PersistenceError) {
        guard let existing = try record(id: id) else {
            return
        }
        modelContext.delete(existing)
        try saveContext()
    }

    func deleteAll() throws(PersistenceError) {
        do {
            try modelContext.delete(model: TripRecord.self)
        } catch {
            Logger.persistence.error("Delete all failed: \(String(describing: error), privacy: .private)")
            throw .saveFailed
        }
        try saveContext()
    }

    /// Finds the stored record for a trip ID.
    /// - Parameter id: The trip's ID.
    /// - Returns: The record, or `nil` if none has that ID.
    private func record(id: UUID) throws(PersistenceError) -> TripRecord? {
        var descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    /// Runs a fetch and turns any failure into a `PersistenceError`.
    /// - Parameter descriptor: What to fetch.
    /// - Returns: The matching records.
    private func fetch(_ descriptor: FetchDescriptor<TripRecord>) throws(PersistenceError) -> [TripRecord] {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.persistence.error("Fetch failed: \(String(describing: error), privacy: .private)")
            throw .fetchFailed
        }
    }

    /// Writes pending changes to disk.
    private func saveContext() throws(PersistenceError) {
        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save failed: \(String(describing: error), privacy: .private)")
            throw .saveFailed
        }
    }
}
