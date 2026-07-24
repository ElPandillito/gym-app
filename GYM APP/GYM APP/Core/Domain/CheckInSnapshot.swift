//
//  CheckInSnapshot.swift
//  GYM APP
//

import Foundation

/// Immutable value-type mirror of CheckIn + related measurements.
/// Passed to Engines to avoid SwiftData model graph dependencies.
struct CheckInSnapshot: Sendable {
    let id: UUID
    let date: Date
    let athleteID: UUID
    let bodyMetrics: BodyMetricsSnapshot?
    let circumferences: CircumferencesSnapshot?
    let skinfolds: SkinfoldSnapshot?
    let photoCount: Int
    let hasCoachNote: Bool
    let hasAthleteNote: Bool

    init(from checkIn: CheckIn) {
        id           = checkIn.id
        date         = checkIn.date
        athleteID    = checkIn.athlete?.id ?? UUID()
        bodyMetrics  = checkIn.bodyMetrics.map(BodyMetricsSnapshot.init)
        circumferences = checkIn.circumferences.map(CircumferencesSnapshot.init)
        skinfolds    = checkIn.skinfolds.map(SkinfoldSnapshot.init)
        photoCount   = checkIn.photos.count
        hasCoachNote   = !(checkIn.coachNote?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        hasAthleteNote = !(checkIn.athleteNote?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
    }
}

// MARK: - BodyMetricsSnapshot

struct BodyMetricsSnapshot: Sendable {
    let bodyWeight: Double?
    let bmi: Double?
    let bodyFatPercentage: Double?
    let muscleMass: Double?
    let boneMass: Double?
    let waterPercentage: Double?
    let visceralFatLevel: Double?
    let basalMetabolicRate: Double?

    init(from m: BodyMetrics) {
        bodyWeight         = m.bodyWeight
        bmi                = m.bmi
        bodyFatPercentage  = m.bodyFatPercentage
        muscleMass         = m.muscleMass
        boneMass           = m.boneMass
        waterPercentage    = m.waterPercentage
        visceralFatLevel   = m.visceralFatLevel
        basalMetabolicRate = m.basalMetabolicRate
    }
}

// MARK: - CircumferencesSnapshot

struct CircumferencesSnapshot: Sendable {
    let neck: Double?
    let shoulders: Double?
    let chest: Double?
    let rightArm: Double?
    let leftArm: Double?
    let rightForearm: Double?
    let leftForearm: Double?
    let waist: Double?
    let abdomen: Double?
    let hips: Double?
    let rightThigh: Double?
    let leftThigh: Double?
    let rightCalf: Double?
    let leftCalf: Double?

    init(from c: CircumferenceMeasurements) {
        neck         = c.neck
        shoulders    = c.shoulders
        chest        = c.chest
        rightArm     = c.rightArm
        leftArm      = c.leftArm
        rightForearm = c.rightForearm
        leftForearm  = c.leftForearm
        waist        = c.waist
        abdomen      = c.abdomen
        hips         = c.hips
        rightThigh   = c.rightThigh
        leftThigh    = c.leftThigh
        rightCalf    = c.rightCalf
        leftCalf     = c.leftCalf
    }
}

// MARK: - SkinfoldSnapshot

struct SkinfoldSnapshot: Sendable {
    let method: PlicometryMethod
    let bodyDensity: Double?
    let estimatedBodyFatPercentage: Double?

    init(from s: SkinfoldMeasurements) {
        method                    = s.method
        bodyDensity               = s.bodyDensity
        estimatedBodyFatPercentage = s.estimatedBodyFatPercentage
    }
}

#if DEBUG
extension CheckInSnapshot {
    static func mock(
        id: UUID = UUID(),
        date: Date = Date(),
        athleteID: UUID = UUID(),
        weight: Double? = 80.0,
        bodyFat: Double? = 15.0
    ) -> CheckInSnapshot {
        var snap = CheckInSnapshot.__mock()
        return snap
    }

    // Memberwise mock — avoids full model graph
    private static func __mock() -> CheckInSnapshot {
        CheckInSnapshot(
            id: UUID(), date: Date(), athleteID: UUID(),
            bodyMetrics: nil, circumferences: nil, skinfolds: nil,
            photoCount: 0, hasCoachNote: false, hasAthleteNote: false
        )
    }

    init(
        id: UUID, date: Date, athleteID: UUID,
        bodyMetrics: BodyMetricsSnapshot?,
        circumferences: CircumferencesSnapshot?,
        skinfolds: SkinfoldSnapshot?,
        photoCount: Int,
        hasCoachNote: Bool,
        hasAthleteNote: Bool
    ) {
        self.id             = id
        self.date           = date
        self.athleteID      = athleteID
        self.bodyMetrics    = bodyMetrics
        self.circumferences = circumferences
        self.skinfolds      = skinfolds
        self.photoCount     = photoCount
        self.hasCoachNote   = hasCoachNote
        self.hasAthleteNote = hasAthleteNote
    }
}
#endif
