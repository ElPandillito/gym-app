//
//  NavigationTarget.swift
//  GYM APP
//

import Foundation

/// Typed navigation destination resolved by the View from the already-loaded athlete data.
/// Uses UUID identifiers instead of SwiftData @Model references so TimelineItem stays a pure Sendable value type.
enum NavigationTarget: Equatable, Sendable {
    case checkIn(id: UUID)
    case photos(checkInID: UUID)
    case bodyMetrics(checkInID: UUID)
    case circumferences(checkInID: UUID)
    case skinfolds(checkInID: UUID)
    case coachNote(checkInID: UUID)
    case athleteNote(checkInID: UUID)
}
