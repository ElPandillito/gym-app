//
//  CircumferenceMeasurementsRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct CircumferenceMeasurementsRepository: CircumferenceMeasurementsRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Inserts the measurements object if new, then persists all changes.
    func save(_ measurements: CircumferenceMeasurements, for checkIn: CheckIn) throws {
        if checkIn.circumferences == nil {
            measurements.checkIn = checkIn
            context.insert(measurements)
        }
        measurements.updatedAt = Date()
        checkIn.updatedAt      = Date()
        try context.save()
    }

    func delete(_ measurements: CircumferenceMeasurements, from checkIn: CheckIn) throws {
        checkIn.circumferences = nil
        context.delete(measurements)
        checkIn.updatedAt = Date()
        try context.save()
    }
}
