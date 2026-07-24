//
//  BodyMetrics.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class BodyMetrics {
    @Attribute(.unique) var id: UUID

    // Body composition
    var bodyWeight: Double?             // kg
    var bodyFatPercentage: Double?      // %
    var muscleMass: Double?             // kg
    var boneMass: Double?               // kg
    var waterPercentage: Double?        // %
    var visceralFatLevel: Double?       // scale 1–59
    var bmi: Double?                    // kg/m²
    var basalMetabolicRate: Double?     // kcal/day

    var createdAt: Date
    var updatedAt: Date

    // Parent
    var checkIn: CheckIn?

    init() {
        self.id        = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
