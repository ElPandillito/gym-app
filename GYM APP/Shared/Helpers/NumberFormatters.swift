//
//  NumberFormatters.swift
//  GYM APP
//

import Foundation

/// Shared NumberFormatter instances for consistent metric display.
enum AppNumberFormatters {

    static let oneDecimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle          = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        f.locale               = Locale(identifier: "es_MX")
        return f
    }()

    static let twoDecimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle          = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.locale               = Locale(identifier: "es_MX")
        return f
    }()

    static let percentage: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle          = .percent
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        f.multiplier           = 1
        f.locale               = Locale(identifier: "es_MX")
        return f
    }()

    static let integer: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale      = Locale(identifier: "es_MX")
        return f
    }()
}

extension Double {
    var kg1: String     { (AppNumberFormatters.twoDecimal.string(from: NSNumber(value: self)) ?? "—") + " kg" }
    var cm1: String     { (AppNumberFormatters.oneDecimal.string(from: NSNumber(value: self)) ?? "—") + " cm" }
    var pct1: String    { (AppNumberFormatters.oneDecimal.string(from: NSNumber(value: self)) ?? "—") + " %" }
    var kcal0: String   { (AppNumberFormatters.integer.string(from: NSNumber(value: self)) ?? "—") + " kcal" }
    var mm1: String     { (AppNumberFormatters.oneDecimal.string(from: NSNumber(value: self)) ?? "—") + " mm" }
}
