//
//  ISAKBreadthsRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct ISAKBreadthsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ breadths: ISAKBreadthsMeasurements, for checkIn: CheckIn) throws {
        if checkIn.isakBreadths == nil {
            breadths.checkIn = checkIn
            context.insert(breadths)
        }
        breadths.updatedAt = Date()
        checkIn.updatedAt  = Date()
        try context.save()
    }

    func delete(_ breadths: ISAKBreadthsMeasurements, from checkIn: CheckIn) throws {
        checkIn.isakBreadths = nil
        context.delete(breadths)
        checkIn.updatedAt = Date()
        try context.save()
    }

    // Insert-only variant — no context.save(). Orchestrator controls commit.
    func insertNew(_ breadths: ISAKBreadthsMeasurements, for checkIn: CheckIn) {
        if checkIn.isakBreadths == nil {
            breadths.checkIn = checkIn
            context.insert(breadths)
        }
        breadths.updatedAt = Date()
        checkIn.updatedAt  = Date()
    }
}
