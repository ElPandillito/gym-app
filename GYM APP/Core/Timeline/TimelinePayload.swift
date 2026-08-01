//
//  TimelinePayload.swift
//  GYM APP
//

import Foundation

enum TimelinePayload: Equatable, Sendable {

    // MARK: - Phase 11 (implemented)

    case checkIn(
        weight: Double?,
        bodyFat: Double?,
        muscleMass: Double?,
        photoCount: Int,
        hasNotes: Bool
    )
    case bodyMetrics(
        weight: Double?,
        bmi: Double?,
        bodyFat: Double?,
        muscleMass: Double?
    )
    case circumference(
        waist: Double?,
        hips: Double?,
        chest: Double?,
        measurementCount: Int
    )
    case skinfolds(method: PlicometryMethod, bodyFat: Double?)
    case photoSession(count: Int, poses: [PoseType])
    case coachNote(text: String)
    case athleteNote(text: String)

    // MARK: - Future (Phase 12+)

    case nutrition
    case workout
    case competition
    case labResult
    case attachment
    case aiInsight

    // MARK: - Escape hatch

    case custom([String: String])
}
