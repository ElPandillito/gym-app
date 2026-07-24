//
//  String+Extensions.swift
//  GYM APP
//

import Foundation

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var isBlank: Bool   { trimmed.isEmpty }
    var nilIfBlank: String? { isBlank ? nil : self }

    /// Parses a locale-agnostic decimal string (supports both "," and ".").
    var asDouble: Double? {
        let clean = replacingOccurrences(of: ",", with: ".")
                      .trimmingCharacters(in: .whitespaces)
        guard let v = Double(clean), v.isFinite else { return nil }
        return v
    }

    /// Parses a positive decimal — returns nil for zero or negative values.
    var asPositiveDouble: Double? {
        guard let v = asDouble, v > 0 else { return nil }
        return v
    }
}
