//
//  CircumferenceMeasurements.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class CircumferenceMeasurements {
    @Attribute(.unique) var id: UUID

    // All values in centimeters
    var neck: Double?
    var shoulders: Double?
    var chest: Double?
    var rightArm: Double?
    var leftArm: Double?
    var rightForearm: Double?
    var leftForearm: Double?
    var waist: Double?
    var abdomen: Double?
    var hips: Double?
    var rightThigh: Double?
    var leftThigh: Double?
    var rightCalf: Double?
    var leftCalf: Double?

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
