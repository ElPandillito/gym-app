//
//  DataPoint.swift
//  GYM APP
//

import Foundation

/// A single (date, value) pair used in time-series data.
struct DataPoint: Equatable, Sendable {
    let date: Date
    let value: Double
}

/// Identifies a body composition metric for time-series lookups.
enum MetricKey: String, CaseIterable, Sendable {
    case weight             = "weight"
    case bmi                = "bmi"
    case bodyFat            = "body_fat"
    case muscleMass         = "muscle_mass"
    case boneMass           = "bone_mass"
    case water              = "water"
    case visceralFat        = "visceral_fat"
    case bmr                = "bmr"
    case skinfoldBodyFat    = "skinfold_body_fat"

    var displayName: String {
        switch self {
        case .weight:           return "Peso"
        case .bmi:              return "IMC"
        case .bodyFat:          return "% Grasa"
        case .muscleMass:       return "Masa muscular"
        case .boneMass:         return "Masa ósea"
        case .water:            return "Agua corporal"
        case .visceralFat:      return "Grasa visceral"
        case .bmr:              return "TMB"
        case .skinfoldBodyFat:  return "% Grasa (plicometría)"
        }
    }
}
