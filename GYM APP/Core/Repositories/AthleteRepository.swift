//
//  AthleteRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct AthleteRepository: AthleteRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ athlete: Athlete) throws {
        context.insert(athlete)
        try context.save()
    }

    func update(_ athlete: Athlete) throws {
        athlete.updatedAt = Date()
        try context.save()
    }

    func delete(_ athlete: Athlete) throws {
        context.delete(athlete)
        try context.save()
    }
}
