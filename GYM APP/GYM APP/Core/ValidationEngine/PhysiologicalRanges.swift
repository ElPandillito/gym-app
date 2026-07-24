//
//  PhysiologicalRanges.swift
//  GYM APP
//

import Foundation

/// Scientifically grounded physiological boundaries used across all validators.
enum PhysiologicalRanges {

    enum Weight {
        static let min: Double = 20.0       // kg — extreme low
        static let max: Double = 350.0      // kg — extreme high
        static let warningMin: Double = 40.0
        static let warningMax: Double = 200.0
    }

    enum Height {
        static let min: Double = 50.0       // cm
        static let max: Double = 250.0      // cm
        static let warningMin: Double = 100.0
        static let warningMax: Double = 230.0
    }

    enum BodyFat {
        static let min: Double = 2.0        // % — essential fat
        static let max: Double = 65.0       // %
        static let warningMin: Double = 4.0
        static let warningMax: Double = 55.0
    }

    enum MuscleMass {
        static let min: Double = 10.0       // kg
        static let max: Double = 120.0      // kg
    }

    enum BoneMass {
        static let min: Double = 0.5        // kg
        static let max: Double = 8.0        // kg
    }

    enum WaterPercentage {
        static let min: Double = 20.0       // %
        static let max: Double = 80.0       // %
        static let warningMin: Double = 40.0
        static let warningMax: Double = 75.0
    }

    enum VisceralFat {
        static let min: Double = 1.0
        static let max: Double = 30.0
        static let warningMax: Double = 12.0
    }

    enum BasalMetabolicRate {
        static let min: Double = 500.0      // kcal/day
        static let max: Double = 5000.0     // kcal/day
    }

    enum Skinfold {
        static let min: Double = 1.0        // mm
        static let max: Double = 80.0       // mm
    }

    enum Circumference {
        static let min: Double = 5.0        // cm
        static let max: Double = 200.0      // cm
    }

    enum Age {
        static let min: Double = 10.0       // years
        static let max: Double = 100.0      // years
    }
}
