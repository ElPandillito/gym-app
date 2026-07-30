//
//  TimelineItem.swift
//  GYM APP
//

import Foundation

struct TimelineItem: Identifiable, Equatable, Sendable {

    /// Stable across rebuilds — format: "\(checkInID.uuidString)-\(type.rawValue)"
    let id: String

    let type: TimelineItemType
    let date: Date
    let title: String
    let subtitle: String?

    let payload: TimelinePayload
    let navigationTarget: NavigationTarget?
}
