import Foundation
import SwiftData

extension SenpengSchemaV1 {

    /// How a `Trip` is stored in the on-device database.
    ///
    /// Only simple values are stored (text, dates, numbers), so the layout stays
    /// stable. Enums are saved by their raw value. The rest of the app never sees
    /// this type; repositories convert it to and from `Trip`.
    @Model
    final class TripRecord {

        /// Same as `Trip.id`. Unique, so saving a trip twice updates it instead of copying it.
        @Attribute(.unique) var id: UUID
        var line: String
        var transportModeRawValue: String
        var lineDestination: String
        var journeyID: String?
        var originID: String
        var originName: String
        var originGlobalID: String
        var destinationID: String
        var destinationName: String
        var destinationGlobalID: String
        var scheduledDeparture: Date
        var scheduledArrival: Date
        var actualArrival: Date?
        var delaySourceRawValue: String?
        var claimStatusRawValue: String
        var createdAt: Date

        /// Creates a record from a trip.
        /// - Parameter trip: The trip to store.
        init(trip: Trip) {
            id = trip.id
            line = trip.line
            transportModeRawValue = trip.transportMode.rawValue
            lineDestination = trip.lineDestination
            journeyID = trip.journeyID
            originID = trip.origin.id
            originName = trip.origin.name
            originGlobalID = trip.origin.globalID
            destinationID = trip.destination.id
            destinationName = trip.destination.name
            destinationGlobalID = trip.destination.globalID
            scheduledDeparture = trip.scheduledDeparture
            scheduledArrival = trip.scheduledArrival
            actualArrival = trip.actualArrival
            delaySourceRawValue = trip.delaySource?.rawValue
            claimStatusRawValue = trip.claimStatus.rawValue
            createdAt = trip.createdAt
        }

        /// Copies the changeable values of a trip into this record.
        ///
        /// Only values that can change after saving are copied: the real arrival,
        /// how it was measured, and the claim status.
        /// - Parameter trip: The updated trip with the same ID.
        func update(from trip: Trip) {
            actualArrival = trip.actualArrival
            delaySourceRawValue = trip.delaySource?.rawValue
            claimStatusRawValue = trip.claimStatus.rawValue
        }

        /// Converts the record back to a trip.
        /// - Returns: The trip.
        /// - Throws: `PersistenceError.corruptedRecord` if a stored value isn't valid.
        func toTrip() throws(PersistenceError) -> Trip {
            guard
                let transportMode = TransportMode(rawValue: transportModeRawValue),
                let claimStatus = ClaimStatus(rawValue: claimStatusRawValue)
            else {
                throw .corruptedRecord
            }

            // A delay source that can't be read is dropped instead of failing the whole
            // trip; the delay can be looked up again.
            let delaySource = delaySourceRawValue.flatMap(DelaySource.init(rawValue:))

            return Trip(
                id: id,
                line: line,
                transportMode: transportMode,
                lineDestination: lineDestination,
                journeyID: journeyID,
                origin: TransportStop(id: originID, name: originName, globalID: originGlobalID),
                destination: TransportStop(id: destinationID, name: destinationName, globalID: destinationGlobalID),
                scheduledDeparture: scheduledDeparture,
                scheduledArrival: scheduledArrival,
                actualArrival: actualArrival,
                delaySource: delaySource,
                claimStatus: claimStatus,
                createdAt: createdAt
            )
        }
    }
}
