//
//  AnthropometryProfile.swift
//  GYM APP
//

import Foundation

/// Selectable anthropometry assessment profile for a Check-In.
/// Stored as raw String in SwiftData (`CheckIn.anthropometryProfileID`) for schema stability.
///
/// ISAK Level 3 is an Instructor accreditation credential, NOT a separate measurement profile.
/// Level 3 instructors use the Full Profile (Level 2) measurement set.
/// Model Level 3 as an instructor metadata field in a future phase — not as a separate profile case.
enum AnthropometryProfile: String, Codable, CaseIterable, Sendable {
    case standard   = "standard"
    case isakLevel1 = "isak_level1"
    case isakLevel2 = "isak_level2"

    var displayName: String {
        switch self {
        case .standard:   return "Estándar GYM APP"
        case .isakLevel1: return "ISAK Nivel 1"
        case .isakLevel2: return "ISAK Nivel 2"
        }
    }

    var subtitle: String {
        switch self {
        case .standard:   return "Métricas generales de composición corporal"
        case .isakLevel1: return "Perfil Restringido · 21 medidas"
        case .isakLevel2: return "Perfil Completo · 43 medidas"
        }
    }

    var icon: String {
        switch self {
        case .standard:   return "figure.stand"
        case .isakLevel1: return "ruler"
        case .isakLevel2: return "ruler.fill"
        }
    }

    /// True when the profile follows the ISAK measurement standard (Level 1 or Level 2).
    var isISAK: Bool { self != .standard }

    /// True for the ISAK Full Profile (Level 2 and — when modelled in future — Level 3 Instructor).
    var isFullProfile: Bool { self == .isakLevel2 }

    var totalMeasurementCount: Int {
        AnthropometryMeasurementCatalog.definitions(for: self).count
    }

    /// Human-readable label for the Review step.
    var reviewLabel: String {
        switch self {
        case .standard:   return "Estándar"
        case .isakLevel1: return "ISAK Nivel 1 — Perfil Restringido"
        case .isakLevel2: return "ISAK Nivel 2 — Perfil Completo"
        }
    }
}
