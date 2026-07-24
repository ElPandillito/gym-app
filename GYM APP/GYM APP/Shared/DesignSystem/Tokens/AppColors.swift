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
    static let background    = Color(.systemBackground)
    static let secondaryBg   = Color(.secondarySystemBackground)
    static let groupedBg     = Color(.systemGroupedBackground)

    // MARK: - Text
    static let primaryText   = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText  = Color(.tertiaryLabel)

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
        static let flat     = Color(.secondaryLabel)
    }
}
