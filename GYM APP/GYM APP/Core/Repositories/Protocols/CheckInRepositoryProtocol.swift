//
//  CheckInRepositoryProtocol.swift
//  GYM APP
//

import Foundation

protocol CheckInRepositoryProtocol {
    func add(_ checkIn: CheckIn, to athlete: Athlete) throws
    func update(_ checkIn: CheckIn) throws
    func delete(_ checkIn: CheckIn) throws
    func saveNotes(coachText: String, athleteText: String, for checkIn: CheckIn) throws
}
