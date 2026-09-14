//
//  AppUnitFormatter.swift
//  GYM APP
//
//  Single source of truth for unit-aware measurement formatting.
//  Domain values are stored in canonical metric units (kg, cm).
//  This formatter converts to the coach's preferred display units.
//

import Foundation

/// Converts canonical metric measurements (kg, cm) to the coach's preferred units for display.
/// Domain values remain stored in metric units — only the presentation layer uses this formatter.
struct AppUnitFormatter: Sendable {

    let preferences: CoachPreferences

    static let metric = AppUnitFormatter(preferences: .default)

    // MARK: - Weight

    var weightLabel: String { preferences.preferredWeightUnit.label }

    func weight(_ kg: Double) -> String {
        String(format: "%.1f \(weightLabel)", convertedWeight(kg))
    }

    func weightOptional(_ kg: Double?) -> String {
        guard let kg else { return "—" }
        return weight(kg)
    }

    func weightDelta(_ kg: Double) -> String {
        let v    = convertedWeight(kg)
        let sign = v > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", v)) \(weightLabel)"
    }

    func convertedWeight(_ kg: Double) -> Double {
        switch preferences.preferredWeightUnit {
        case .kg: return kg
        case .lb: return kg * 2.20462
        }
    }

    /// Formats a per-day OLS slope (kg/day) as a monthly rate string, e.g. "+0.4 kg/mes".
    func weightSlopeMonthly(_ kgPerDay: Double) -> String {
        let monthly = convertedWeight(kgPerDay * 30)
        let sign    = monthly > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", monthly)) \(weightLabel)/mes"
    }

    // MARK: - Length

    var lengthLabel: String {
        switch preferences.preferredLengthUnit {
        case .cm:     return "cm"
        case .inches: return "in"
        }
    }

    func length(_ cm: Double) -> String {
        String(format: "%.1f \(lengthLabel)", convertedLength(cm))
    }

    func lengthOptional(_ cm: Double?) -> String {
        guard let cm else { return "—" }
        return length(cm)
    }

    func lengthDelta(_ cm: Double) -> String {
        let v    = convertedLength(cm)
        let sign = v > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", v)) \(lengthLabel)"
    }

    func convertedLength(_ cm: Double) -> Double {
        switch preferences.preferredLengthUnit {
        case .cm:     return cm
        case .inches: return cm * 0.393701
        }
    }

    /// Formats a per-day OLS slope (cm/day) as a monthly rate string, e.g. "-0.5 cm/mes".
    func lengthSlopeMonthly(_ cmPerDay: Double) -> String {
        let monthly = convertedLength(cmPerDay * 30)
        let sign    = monthly > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", monthly)) \(lengthLabel)/mes"
    }

    // MARK: - Height (integer cm or one-decimal in)

    func height(_ cm: Double) -> String {
        switch preferences.preferredLengthUnit {
        case .cm:     return String(format: "%.0f cm", cm)
        case .inches: return String(format: "%.1f in", cm * 0.393701)
        }
    }

    func heightOptional(_ cm: Double?) -> String {
        guard let cm else { return "—" }
        return height(cm)
    }

    // MARK: - Input → Canonical (inverse conversions for input forms)

    /// Converts a user-entered value (in the preferred weight unit) back to canonical kilograms.
    func toCanonicalWeight(_ displayValue: Double) -> Double {
        switch preferences.preferredWeightUnit {
        case .kg: return displayValue
        case .lb: return displayValue / 2.20462
        }
    }

    /// Converts a user-entered value (in the preferred length unit) back to canonical centimeters.
    func toCanonicalLength(_ displayValue: Double) -> Double {
        switch preferences.preferredLengthUnit {
        case .cm:     return displayValue
        case .inches: return displayValue / 0.393701
        }
    }
}
