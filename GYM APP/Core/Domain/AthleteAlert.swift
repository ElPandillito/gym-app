//
//  AthleteAlert.swift
//  GYM APP
//
//  Single source of truth for per-athlete alerts.
//  Used by both DashboardViewModel and AthleteOverviewViewModel.
//

import Foundation

// MARK: - AthleteAlert

struct AthleteAlert: Identifiable, Sendable {

    enum Kind: Sendable {
        case inactive(days: Int)
        case negativeTrend
        case noPhotos
        case incompleteMetrics
    }

    let athleteID: UUID
    let athleteName: String
    let kind: Kind

    /// Deterministic: same athlete + same kind → same ID across reloads.
    var id: String { athleteID.uuidString + "-" + kind.stableKey }

    var severity: Int {
        switch kind {
        case .inactive:          return 3
        case .negativeTrend:     return 2
        case .noPhotos:          return 1
        case .incompleteMetrics: return 1
        }
    }
}

// MARK: - Kind helpers

extension AthleteAlert.Kind {
    var stableKey: String {
        switch self {
        case .inactive:          return "inactive"
        case .negativeTrend:     return "negativeTrend"
        case .noPhotos:          return "noPhotos"
        case .incompleteMetrics: return "incompleteMetrics"
        }
    }
}
