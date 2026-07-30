//
//  TimelineItemType.swift
//  GYM APP
//

import Foundation

// MARK: - TimelineItemType

enum TimelineItemType: String, Codable, Hashable, Sendable {

    // MARK: Phase 11 — implemented
    case checkIn
    case bodyMetrics
    case circumference
    case skinfolds
    case photoSession
    case coachNote
    case athleteNote

    // MARK: Future phases — architecture ready, no builder logic yet
    case nutrition
    case workout
    case competition
    case labResult
    case attachment
    case aiInsight
    case custom
}

// MARK: - Display order

extension TimelineItemType {
    /// Ascending display priority within a day group.
    /// `.checkIn` is always the anchor event (priority 0).
    var displayPriority: Int {
        switch self {
        case .checkIn:       return 0
        case .photoSession:  return 1
        case .bodyMetrics:   return 2
        case .circumference: return 3
        case .skinfolds:     return 4
        case .coachNote:     return 5
        case .athleteNote:   return 6
        case .nutrition:     return 7
        case .workout:       return 8
        case .competition:   return 9
        case .labResult:     return 10
        case .attachment:    return 11
        case .aiInsight:     return 12
        case .custom:        return 99
        }
    }
}
