//
//  SkinfoldMeasurements.swift
//  GYM APP
//

import SwiftData
import Foundation

@Model
final class SkinfoldMeasurements {
    @Attribute(.unique) var id: UUID
    var method: PlicometryMethod

    // All values in millimeters
    var chest: Double?
    var midaxillary: Double?
    var tricep: Double?
    var subscapular: Double?
    var abdomen: Double?
    var suprailiac: Double?
    var thigh: Double?
    var calf: Double?
    var bicep: Double?
    var lowerBack: Double?

    // ISAK-specific skinfold sites (distinct from the generic `suprailiac` used by JP/Parrillo)
    var iliacCrest: Double?     // mm — cresta ilíaca ISAK (oblique fold, superior to crest)
    var supraspinale: Double?   // mm — supraespinal ISAK (ASIS → anterior axillary intersection)

    // Stored results — immutable once calculated to preserve historical accuracy
    var bodyDensity: Double?
    var estimatedBodyFatPercentage: Double?

    // Measurement context
    var tester: String?
    var caliperBrand: String?

    var createdAt: Date
    var updatedAt: Date

    // Parent
    var checkIn: CheckIn?

    init(method: PlicometryMethod = .jacksonPollockSeven) {
        self.id        = UUID()
        self.method    = method
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
