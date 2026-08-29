//
//  DashboardFilter.swift
//  GYM APP
//

import Foundation

// MARK: - DashboardFilter

enum DashboardFilter: String, Codable, Hashable, CaseIterable, Sendable, Identifiable {
    case all         = "Todos"
    case active      = "Activos"
    case inactive    = "Inactivos"
    case competition = "Competencia"
    case bulk        = "Volumen"
    case cut         = "Definición"
    case custom      = "Personalizado"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all:         return "person.2.fill"
        case .active:      return "checkmark.circle.fill"
        case .inactive:    return "clock.badge.exclamationmark"
        case .competition: return "trophy.fill"
        case .bulk:        return "arrow.up.circle.fill"
        case .cut:         return "flame.fill"
        case .custom:      return "slider.horizontal.3"
        }
    }
}

// MARK: - Filter application

extension DashboardFilter {

    /// Filters `athletes` according to the selected filter.
    /// `checkIns` is required for activity-based filters.
    /// `preferences` supplies the inactivity threshold.
    func apply(
        to athletes: [Athlete],
        checkIns: [CheckIn],
        preferences: CoachPreferences
    ) -> [Athlete] {
        switch self {
        case .all:
            return athletes

        case .active:
            let cutoff    = activeCutoff(preferences: preferences)
            let activeIDs = activeAthleteIDs(checkIns: checkIns, since: cutoff)
            return athletes.filter { activeIDs.contains($0.id) }

        case .inactive:
            let cutoff    = activeCutoff(preferences: preferences)
            let activeIDs = activeAthleteIDs(checkIns: checkIns, since: cutoff)
            return athletes.filter { !activeIDs.contains($0.id) }

        case .competition:
            return athletes.filter { $0.phase.isCompetitionPhase }

        case .bulk:
            return athletes.filter { $0.phase.isBulkPhase }

        case .cut:
            return athletes.filter { $0.phase.isCutPhase }

        case .custom:
            // Placeholder until coach-defined criteria are implemented.
            return athletes
        }
    }

    // MARK: - Helpers

    private func activeCutoff(preferences: CoachPreferences) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: -preferences.inactivityThresholdDays,
            to: Date()
        ) ?? Date()
    }

    private func activeAthleteIDs(checkIns: [CheckIn], since cutoff: Date) -> Set<UUID> {
        Set(checkIns
            .filter { $0.date >= cutoff }
            .compactMap { $0.athlete?.id })
    }
}
