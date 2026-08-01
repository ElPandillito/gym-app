//
//  DashboardKPIs.swift
//  GYM APP
//

import Foundation

/// Key Performance Indicators surfaced on the Dashboard.
struct DashboardKPIs: Equatable, Sendable {
    let totalAthletes: Int
    let totalCheckIns: Int
    let checkInsThisMonth: Int
    let averageDaysBetweenCheckIns: Double?
    let mostRecentCheckInDate: Date?

    // Global body composition averages (across all athletes, latest check-in per athlete)
    let averageBodyFat: Double?
    let averageWeight: Double?
    let averageMuscleMass: Double?

    static let empty = DashboardKPIs(
        totalAthletes: 0,
        totalCheckIns: 0,
        checkInsThisMonth: 0,
        averageDaysBetweenCheckIns: nil,
        mostRecentCheckInDate: nil,
        averageBodyFat: nil,
        averageWeight: nil,
        averageMuscleMass: nil
    )
}
