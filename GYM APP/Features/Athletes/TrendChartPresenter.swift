//
//  TrendChartPresenter.swift
//  GYM APP
//

import Foundation

/// Pure data-transformation helper for TrendChartView.
/// Handles unit conversion and value formatting for chart display.
/// No SwiftUI dependency — fully testable in isolation.
struct TrendChartPresenter {
    let metricKey: MetricKey
    let preferences: CoachPreferences

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: preferences) }

    // MARK: - Value conversion

    /// Converts a canonical domain value (stored in metric units) to the display value
    /// in the coach's preferred units.
    func displayValue(for rawValue: Double) -> Double {
        switch metricKey {
        case .weight, .muscleMass, .boneMass:
            return fmt.convertedWeight(rawValue)
        default:
            return rawValue
        }
    }

    // MARK: - Unit label

    var unitLabel: String {
        switch metricKey {
        case .weight, .muscleMass, .boneMass:
            return fmt.weightLabel
        case .bodyFat, .water, .skinfoldBodyFat:
            return "%"
        case .bmi:
            return "kg/m²"
        case .visceralFat:
            return "nivel"
        case .bmr:
            return "kcal"
        }
    }

    // MARK: - Formatting

    func formattedValue(_ value: Double) -> String {
        switch metricKey {
        case .bmr, .visceralFat:
            return String(format: "%.0f", value)
        default:
            return String(format: "%.1f", value)
        }
    }

    func formattedAxisValue(_ value: Double) -> String {
        switch metricKey {
        case .bmr, .visceralFat:
            return String(format: "%.0f", value)
        default:
            return String(format: "%.1f", value)
        }
    }

    // MARK: - Trend rate text

    /// Returns a localized string describing the monthly rate of change.
    func trendRateText(slope: Double, direction: Trend.TrendDirection) -> String {
        switch direction {
        case .insufficient:
            return "—"
        case .flat:
            return "Estable"
        case .rising, .falling:
            break
        }
        switch metricKey {
        case .weight, .muscleMass, .boneMass:
            return fmt.weightSlopeMonthly(slope)
        case .bodyFat, .water, .skinfoldBodyFat:
            let monthly = slope * 30
            let sign = monthly > 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", monthly))%/mes"
        case .bmi:
            let monthly = slope * 30
            let sign = monthly > 0 ? "+" : ""
            return "\(sign)\(String(format: "%.2f", monthly))/mes"
        case .visceralFat, .bmr:
            let monthly = slope * 30
            let sign = monthly > 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", monthly))/mes"
        }
    }
}
