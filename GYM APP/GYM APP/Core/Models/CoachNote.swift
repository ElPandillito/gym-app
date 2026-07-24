//
//  CoachNote.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class CoachNote {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date

    // Parent
    var checkIn: CheckIn?

    init(text: String = "") {
        self.id        = UUID()
        self.text      = text
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
