//
//  Gender.swift
//  GYM APP
//

import Foundation

enum Gender: String, Codable, CaseIterable {
    case male   = "male"
    case female = "female"
    case other  = "other"

    var displayName: String {
        switch self {
        case .male:   return "Masculino"
        case .female: return "Femenino"
        case .other:  return "Otro"
        }
    }
}
