//
//  AthletePhase.swift
//  GYM APP
//

import Foundation

// MARK: - AthletePhase

/// Describes the current training and nutrition phase of an athlete.
///
/// ## Integration roadmap
///
/// **Step 1 — Add to Athlete model (future phase):**
/// ```swift
/// // In Athlete.swift
/// var phase: AthletePhase = .offSeason
/// ```
///
/// **Step 2 — Activate DashboardFilter cases:**
/// In `DashboardFilter.apply(to:checkIns:preferences:)`, replace the
/// passthrough cases with real predicate filters:
/// ```swift
/// case .competition: return athletes.filter { $0.phase == .contestPrep || $0.phase == .peakWeek }
/// case .bulk:        return athletes.filter { $0.phase == .offSeason || $0.phase == .leanBulk }
/// case .cut:         return athletes.filter { $0.phase == .miniCut || $0.phase == .reverseDiet }
/// ```
///
/// **Step 3 — Surface in AthleteFormView:**
/// Add a `Picker` for `AthletePhase` alongside existing athlete fields.
enum AthletePhase: String, Codable, Hashable, CaseIterable, Sendable {

    /// General off-season; no specific competition timeline.
    case offSeason     = "offSeason"

    /// Controlled caloric surplus targeting muscle gain with minimal fat gain.
    case leanBulk      = "leanBulk"

    /// Short, focused fat-loss block preserving muscle mass.
    case miniCut       = "miniCut"

    /// Competition preparation phase with structured deficit and peak conditioning.
    case contestPrep   = "contestPrep"

    /// Final week of competition prep: water/carb manipulation for stage peak.
    case peakWeek      = "peakWeek"

    /// Post-competition caloric ramp-up to restore metabolic rate.
    case reverseDiet   = "reverseDiet"

    /// Maintenance calories; body recomposition or lifestyle focus.
    case maintenance   = "maintenance"

    /// Coach-defined phase outside the standard categories.
    case custom        = "custom"

    // MARK: Display

    var displayName: String {
        switch self {
        case .offSeason:   return "Fuera de Temporada"
        case .leanBulk:    return "Volumen Limpio"
        case .miniCut:     return "Mini Definición"
        case .contestPrep: return "Preparación de Competencia"
        case .peakWeek:    return "Peak Week"
        case .reverseDiet: return "Dieta Inversa"
        case .maintenance: return "Mantenimiento"
        case .custom:      return "Personalizado"
        }
    }

    var systemImage: String {
        switch self {
        case .offSeason:   return "moon.zzz.fill"
        case .leanBulk:    return "arrow.up.circle.fill"
        case .miniCut:     return "scissors"
        case .contestPrep: return "trophy.fill"
        case .peakWeek:    return "star.fill"
        case .reverseDiet: return "arrow.up.arrow.down.circle"
        case .maintenance: return "equal.circle.fill"
        case .custom:      return "slider.horizontal.3"
        }
    }

    /// Whether this phase is competition-oriented (used by DashboardFilter.competition).
    var isCompetitionPhase: Bool {
        self == .contestPrep || self == .peakWeek
    }

    /// Whether this phase is a bulk-oriented phase (used by DashboardFilter.bulk).
    var isBulkPhase: Bool {
        self == .offSeason || self == .leanBulk
    }

    /// Whether this phase is a cut-oriented phase (used by DashboardFilter.cut).
    var isCutPhase: Bool {
        self == .miniCut || self == .reverseDiet
    }
}
