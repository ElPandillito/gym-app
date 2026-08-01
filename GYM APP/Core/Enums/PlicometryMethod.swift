//
//  PlicometryMethod.swift
//  GYM APP
//

import Foundation

enum PlicometryMethod: String, Codable, CaseIterable {
    case jacksonPollockThree = "jackson_pollock_3"
    case jacksonPollockSeven = "jackson_pollock_7"
    case durninWomersley     = "durnin_womersley"
    case parrillo            = "parrillo"
    case custom              = "custom"

    var displayName: String {
        switch self {
        case .jacksonPollockThree: return "Jackson-Pollock 3"
        case .jacksonPollockSeven: return "Jackson-Pollock 7"
        case .durninWomersley:     return "Durnin-Womersley"
        case .parrillo:            return "Parrillo"
        case .custom:              return "Personalizado"
        }
    }

    var siteCount: Int {
        switch self {
        case .jacksonPollockThree: return 3
        case .jacksonPollockSeven: return 7
        case .durninWomersley:     return 4
        case .parrillo:            return 9
        case .custom:              return 0
        }
    }
}
