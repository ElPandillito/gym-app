//
//  CheckIn.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class CheckIn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // Parent
    var athlete: Athlete?

    // One-to-one children (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \BodyMetrics.checkIn)
    var bodyMetrics: BodyMetrics?

    @Relationship(deleteRule: .cascade, inverse: \CircumferenceMeasurements.checkIn)
    var circumferences: CircumferenceMeasurements?

    @Relationship(deleteRule: .cascade, inverse: \SkinfoldMeasurements.checkIn)
    var skinfolds: SkinfoldMeasurements?

    @Relationship(deleteRule: .cascade, inverse: \CoachNote.checkIn)
    var coachNote: CoachNote?

    @Relationship(deleteRule: .cascade, inverse: \AthleteNote.checkIn)
    var athleteNote: AthleteNote?

    // One-to-many children (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \ProgressPhoto.checkIn)
    var photos: [ProgressPhoto]

    init(date: Date = Date()) {
        self.id        = UUID()
        self.date      = date
        self.createdAt = Date()
        self.updatedAt = Date()
        self.photos    = []
    }
}
