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

    // ISAK Level 1 girth (not in standard profile)
    var armFlexedTensed: Double?        // cm — brazo contraído máximo

    // ISAK Level 2 additional girths
    var headGirth: Double?              // cm — perímetro cefálico
    var wristGirth: Double?             // cm — muñeca
    var ankleGirth: Double?             // cm — tobillo
    var midThighGirth: Double?          // cm — muslo medio (≠ existing rightThigh at gluteal fold)
    // g_forearm_max maps to existing rightForearm/leftForearm; g_neck maps to existing neck;
    // g_chest maps to existing chest — no new fields needed for those three.

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
