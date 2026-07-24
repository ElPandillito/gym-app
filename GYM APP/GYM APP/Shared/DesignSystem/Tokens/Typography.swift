//
//  Typography.swift
//  GYM APP
//

import SwiftUI

/// Typography scale tokens. Wraps SwiftUI's dynamic type system.
enum AppTypography {
    static let largeTitle   = Font.largeTitle
    static let title        = Font.title
    static let title2       = Font.title2
    static let title3       = Font.title3
    static let headline     = Font.headline
    static let subheadline  = Font.subheadline
    static let body         = Font.body
    static let callout      = Font.callout
    static let footnote     = Font.footnote
    static let caption      = Font.caption
    static let caption2     = Font.caption2

    // Custom semantic styles
    static let metricValue  = Font.title3.weight(.bold).monospacedDigit()
    static let metricLabel  = Font.footnote
    static let kpiValue     = Font.title.weight(.heavy).monospacedDigit()
    static let kpiLabel     = Font.caption.weight(.medium)
    static let sectionHeader = Font.footnote.weight(.semibold)
}
