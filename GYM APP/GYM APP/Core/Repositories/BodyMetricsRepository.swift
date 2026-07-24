//
//  BodyMetricsRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct BodyMetricsRepository: BodyMetricsRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Inserts the metrics object if new, then persists all changes.
    func save(_ metrics: BodyMetrics, for checkIn: CheckIn) throws {
        if checkIn.bodyMetrics == nil {
            metrics.checkIn = checkIn
            context.insert(metrics)
        }
        metrics.updatedAt = Date()
        checkIn.updatedAt = Date()
        try context.save()
    }

    func delete(_ metrics: BodyMetrics, from checkIn: CheckIn) throws {
        checkIn.bodyMetrics = nil
        context.delete(metrics)
        checkIn.updatedAt = Date()
        try context.save()
    }
}
