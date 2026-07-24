//
//  PoseType.swift
//  GYM APP
//

import Foundation

enum PoseType: String, Codable, CaseIterable {
    case frontRelaxed       = "front_relaxed"
    case frontDoubleBiceps  = "front_double_biceps"
    case backRelaxed        = "back_relaxed"
    case backDoubleBiceps   = "back_double_biceps"
    case sideChestLeft      = "side_chest_left"
    case sideChestRight     = "side_chest_right"
    case sideTricepsLeft    = "side_triceps_left"
    case sideTricepsRight   = "side_triceps_right"
    case mostMuscular       = "most_muscular"
    case vacuum             = "vacuum"
    case custom             = "custom"

    var displayName: String {
        switch self {
        case .frontRelaxed:      return "Front Relaxed"
        case .frontDoubleBiceps: return "Front Double Biceps"
        case .backRelaxed:       return "Back Relaxed"
        case .backDoubleBiceps:  return "Back Double Biceps"
        case .sideChestLeft:     return "Side Chest (Izq)"
        case .sideChestRight:    return "Side Chest (Der)"
        case .sideTricepsLeft:   return "Side Triceps (Izq)"
        case .sideTricepsRight:  return "Side Triceps (Der)"
        case .mostMuscular:      return "Most Muscular"
        case .vacuum:            return "Vacuum"
        case .custom:            return "Libre"
        }
    }

    var sfSymbol: String {
        switch self {
        case .frontRelaxed, .frontDoubleBiceps:    return "figure.stand"
        case .backRelaxed, .backDoubleBiceps:      return "figure.walk"
        case .sideChestLeft, .sideChestRight:      return "figure.arms.open"
        case .sideTricepsLeft, .sideTricepsRight:  return "figure.arms.open"
        case .mostMuscular:                        return "figure.strengthtraining.traditional"
        case .vacuum:                              return "figure.mind.and.body"
        case .custom:                              return "camera"
        }
    }
}
