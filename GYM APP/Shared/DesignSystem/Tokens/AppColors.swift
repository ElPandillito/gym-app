//
//  AppColors.swift
//  GYM APP
//

import SwiftUI

/// Semantic color tokens for the Design System.
/// Use these instead of raw Color values throughout the app.
enum AppColors {

    // MARK: - Brand
    static let accent        = Color.accentColor
    static let brand         = Color("BrandPrimary", bundle: nil)

    // MARK: - Semantic backgrounds
    #if canImport(UIKit)
    static let background         = Color(uiColor: .systemBackground)
    static let secondaryBg        = Color(uiColor: .secondarySystemBackground)
    static let groupedBg          = Color(uiColor: .systemGroupedBackground)
    static let secondaryGroupedBg = Color(uiColor: .secondarySystemGroupedBackground)
    #else
    static let background         = Color(nsColor: .windowBackgroundColor)
    static let secondaryBg        = Color(nsColor: .controlBackgroundColor)
    static let groupedBg          = Color(nsColor: .windowBackgroundColor)
    static let secondaryGroupedBg = Color(nsColor: .controlBackgroundColor)
    #endif

    // MARK: - Text
    #if canImport(UIKit)
    static let primaryText   = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let tertiaryText  = Color(uiColor: .tertiaryLabel)
    #else
    static let primaryText   = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let tertiaryText  = Color(nsColor: .tertiaryLabelColor)
    #endif

    // MARK: - Status
    static let success = Color.green
    static let warning = Color.orange
    static let error   = Color.red
    static let info    = Color.blue

    // MARK: - Body Fat Ranges (UI only — interpretation is context-dependent)
    enum BodyFat {
        static let essential  = Color.blue       // < 10 %
        static let athletic   = Color.green      // 10 – 17 %
        static let fitness    = Color.yellow     // 18 – 24 %
        static let average    = Color.orange     // 25 – 31 %
        static let obese      = Color.red        // ≥ 32 %

        static func color(for percentage: Double) -> Color {
            switch percentage {
            case ..<10:  return essential
            case 10..<18: return athletic
            case 18..<25: return fitness
            case 25..<32: return average
            default:     return obese
            }
        }
    }

    // MARK: - Trend
    enum Trend {
        static let rising   = Color.green
        static let falling  = Color.red
        #if canImport(UIKit)
        static let flat     = Color(uiColor: .secondaryLabel)
        #else
        static let flat     = Color(nsColor: .secondaryLabelColor)
        #endif
    }
}
