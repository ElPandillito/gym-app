//
//  Athlete.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class Athlete {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date?
    var height: Double?             // centimeters
    var gender: Gender
    // Stored as String so null values from pre-phase athletes don't cause a
    // swift_dynamicCastFailure. @Attribute(originalName:) keeps the same DB column.
    @Attribute(originalName: "phase") private var phaseRaw: String = AthletePhase.offSeason.rawValue
    var profilePhotoPath: String?
    var createdAt: Date
    var updatedAt: Date

    /// Safe decoded phase — falls back to `.offSeason` for legacy null values.
    var phase: AthletePhase {
        get { AthletePhase(rawValue: phaseRaw) ?? .offSeason }
        set { phaseRaw = newValue.rawValue }
    }

    @Relationship(deleteRule: .cascade, inverse: \CheckIn.athlete)
    var checkIns: [CheckIn]

    @Relationship(deleteRule: .cascade, inverse: \NutritionPlan.athlete)
    var nutritionPlans: [NutritionPlan]

    init(
        name: String,
        gender: Gender = .other,
        birthDate: Date? = nil,
        height: Double? = nil,
        phase: AthletePhase = .offSeason
    ) {
        self.id             = UUID()
        self.name           = name
        self.gender         = gender
        self.birthDate      = birthDate
        self.height         = height
        self.phaseRaw       = phase.rawValue
        self.createdAt      = Date()
        self.updatedAt      = Date()
        self.checkIns       = []
        self.nutritionPlans = []
    }
}
