//
//  DateFormatters.swift
//  GYM APP
//

import Foundation

/// Shared, reusable DateFormatter instances.
/// DateFormatter creation is expensive — always reuse these singletons.
enum AppDateFormatters {

    /// "23 jul. 2026"
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle  = .medium
        f.timeStyle  = .none
        f.locale     = Locale(identifier: "es_MX")
        return f
    }()

    /// "23/07/2026"
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale     = Locale(identifier: "es_MX")
        return f
    }()

    /// "julio 2026"
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale     = Locale(identifier: "es_MX")
        return f
    }()

    /// ISO 8601 for serialization
    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

extension Date {
    var mediumFormatted: String { AppDateFormatters.mediumDate.string(from: self) }
    var shortFormatted:  String { AppDateFormatters.shortDate.string(from: self) }
    var monthYearFormatted: String { AppDateFormatters.monthYear.string(from: self) }
}
