//
//  ISAKLengthsRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct ISAKLengthsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ lengths: ISAKLengthsMeasurements, for checkIn: CheckIn) throws {
        if checkIn.isakLengths == nil {
            lengths.checkIn = checkIn
            context.insert(lengths)
        }
        lengths.updatedAt = Date()
        checkIn.updatedAt = Date()
        try context.save()
    }

    func delete(_ lengths: ISAKLengthsMeasurements, from checkIn: CheckIn) throws {
        checkIn.isakLengths = nil
        context.delete(lengths)
        checkIn.updatedAt = Date()
        try context.save()
    }

    // Insert-only variant — no context.save(). Orchestrator controls commit.
    func insertNew(_ lengths: ISAKLengthsMeasurements, for checkIn: CheckIn) {
        if checkIn.isakLengths == nil {
            lengths.checkIn = checkIn
            context.insert(lengths)
        }
        lengths.updatedAt = Date()
        checkIn.updatedAt = Date()
    }
}
