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
    var phase: AthletePhase
    var profilePhotoPath: String?
    var createdAt: Date
    var updatedAt: Date

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
        self.phase          = phase
        self.createdAt      = Date()
        self.updatedAt      = Date()
        self.checkIns       = []
        self.nutritionPlans = []
    }
}
