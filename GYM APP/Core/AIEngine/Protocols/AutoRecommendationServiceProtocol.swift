//
//  AutoRecommendationServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for automatic recommendations based on athlete data.
protocol AutoRecommendationServiceProtocol {
    func generateRecommendations(
        athlete: AthleteSnapshot,
        statistics: AthleteStatisticsReport
    ) async throws -> [AIRecommendation]
}

struct AIRecommendation: Sendable, Identifiable {
    let id: UUID
    let category: RecommendationCategory
    let title: String
    let detail: String
    let priority: RecommendationPriority
    let generatedAt: Date
}

enum RecommendationCategory: String, Sendable {
    case bodyComposition = "body_composition"
    case checkInFrequency = "check_in_frequency"
    case photography     = "photography"
    case nutrition       = "nutrition"
    case training        = "training"
}

enum RecommendationPriority: Int, Sendable, Comparable {
    case low    = 0
    case medium = 1
    case high   = 2

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
