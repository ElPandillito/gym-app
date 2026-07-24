//
//  ChangeDirection.swift
//  GYM APP
//

import Foundation

/// Raw direction of a numeric change between two check-ins.
/// The UI layer decides whether a direction is "good" or "bad" based on context.
enum ChangeDirection: Equatable {
    case increased
    case decreased
    case unchanged
    case unavailable    // One or both sides have no data for this metric
}
