//
//  SkinfoldMeasurementsRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct SkinfoldMeasurementsRepository: SkinfoldMeasurementsRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ measurements: SkinfoldMeasurements, for checkIn: CheckIn) throws {
        if checkIn.skinfolds == nil {
            measurements.checkIn = checkIn
            context.insert(measurements)
        }
        measurements.updatedAt = Date()
        checkIn.updatedAt      = Date()
        try context.save()
    }

    func delete(_ measurements: SkinfoldMeasurements, from checkIn: CheckIn) throws {
        checkIn.skinfolds = nil
        context.delete(measurements)
        checkIn.updatedAt = Date()
        try context.save()
    }
}
