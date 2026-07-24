//
//  CheckInRepository.swift
//  GYM APP
//

import SwiftData
import Foundation

struct CheckInRepository: CheckInRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ checkIn: CheckIn, to athlete: Athlete) throws {
        checkIn.athlete = athlete
        context.insert(checkIn)
        try context.save()
    }

    func update(_ checkIn: CheckIn) throws {
        checkIn.updatedAt = Date()
        try context.save()
    }

    func delete(_ checkIn: CheckIn) throws {
        context.delete(checkIn)
        try context.save()
    }

    // Creates, updates, or deletes CoachNote and AthleteNote based on text content.
    // Empty text removes the existing note; non-empty text creates or updates it.
    func saveNotes(coachText: String, athleteText: String, for checkIn: CheckIn) throws {
        let trimmedCoach   = coachText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAthlete = athleteText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCoach.isEmpty {
            if let existing = checkIn.coachNote {
                context.delete(existing)
                checkIn.coachNote = nil
            }
        } else if let existing = checkIn.coachNote {
            existing.text      = trimmedCoach
            existing.updatedAt = Date()
        } else {
            let note      = CoachNote(text: trimmedCoach)
            note.checkIn  = checkIn
            checkIn.coachNote = note
            context.insert(note)
        }

        if trimmedAthlete.isEmpty {
            if let existing = checkIn.athleteNote {
                context.delete(existing)
                checkIn.athleteNote = nil
            }
        } else if let existing = checkIn.athleteNote {
            existing.text      = trimmedAthlete
            existing.updatedAt = Date()
        } else {
            let note      = AthleteNote(text: trimmedAthlete)
            note.checkIn  = checkIn
            checkIn.athleteNote = note
            context.insert(note)
        }

        checkIn.updatedAt = Date()
        try context.save()
    }
}
