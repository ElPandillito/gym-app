//
//  CoachPreferences.swift
//  GYM APP
//

import Foundation

// MARK: - Supporting enums

enum WeightUnit: String, Codable, Hashable, CaseIterable, Sendable {
    case kg
    case lb

    var label: String { rawValue }

    var displayName: String {
        switch self {
        case .kg: return "Kilogramos (kg)"
        case .lb: return "Libras (lb)"
        }
    }
}

enum LengthUnit: String, Codable, Hashable, CaseIterable, Sendable {
    case cm
    case inches

    var label: String { rawValue }

    var displayName: String {
        switch self {
        case .cm:     return "Centímetros (cm)"
        case .inches: return "Pulgadas (in)"
        }
    }
}

// MARK: - CoachPreferences

/// Value-type container for all coach-configurable settings.
/// Currently in-memory only. Prepare for persistence via AppStorage/SwiftData
/// by keeping all stored properties Codable and avoiding mutable computed state.
struct CoachPreferences: Codable, Hashable, Sendable {

    // MARK: Dashboard thresholds

    /// Days without check-in before an athlete is flagged as inactive.
    var inactivityThresholdDays: Int = 14

    /// Rolling window (days) used to compute body fat trend alerts.
    var trendWindowDays: Int = 60

    /// Rolling window (days) used to identify top progressors.
    var progressWindowDays: Int = 30

    /// Maximum number of alerts shown on the dashboard.
    var maxAlertsShown: Int = 10

    // MARK: Alert toggles

    /// Show alerts for athletes who have not checked in recently.
    var showInactiveAlerts: Bool = true

    /// Show alerts for athletes with no photos in their latest check-in.
    var showPhotoAlerts: Bool = true

    /// Show alerts for athletes missing body weight in their latest check-in.
    var showMetricAlerts: Bool = true

    // MARK: Units

    var preferredWeightUnit: WeightUnit = .kg
    var preferredLengthUnit: LengthUnit = .cm

    // MARK: Dashboard filter

    var dashboardFilter: DashboardFilter = .all

    // MARK: Default

    static let `default` = CoachPreferences()
}
