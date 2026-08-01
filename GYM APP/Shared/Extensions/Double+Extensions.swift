//
//  Double+Extensions.swift
//  GYM APP
//

import Foundation

extension Double {
    /// Rounds to N decimal places.
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }

    /// Clamps the value to a closed range.
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }

    /// Returns nil if the value is not finite (NaN, infinity).
    var nilIfNotFinite: Double? { isFinite ? self : nil }

    /// Percentage change from `base` to `self`.
    func percentageChange(from base: Double) -> Double? {
        guard base != 0 else { return nil }
        return ((self - base) / base) * 100
    }
}
