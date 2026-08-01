//
//  MeasurementFormatters.swift
//  GYM APP
//

import Foundation

/// Typed measurement formatters using the Measurement API.
enum AppMeasurementFormatters {

    static let mass: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions        = .providedUnit
        f.numberFormatter.minimumFractionDigits = 2
        f.numberFormatter.maximumFractionDigits = 2
        return f
    }()

    static let length: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions        = .providedUnit
        f.numberFormatter.minimumFractionDigits = 1
        f.numberFormatter.maximumFractionDigits = 1
        return f
    }()

    // MARK: - Convenience

    static func kg(_ value: Double) -> String {
        AppMeasurementFormatters.mass.string(from: Measurement(value: value, unit: UnitMass.kilograms))
    }

    static func cm(_ value: Double) -> String {
        AppMeasurementFormatters.length.string(from: Measurement(value: value, unit: UnitLength.centimeters))
    }
}
