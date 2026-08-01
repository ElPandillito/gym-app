//
//  MetricRecord.swift
//  GYM APP
//

import Foundation

/// A best/worst metric value with its timestamp and check-in reference.
struct MetricRecord: Equatable, Sendable {
    let value: Double
    let date: Date
    let checkInID: UUID
}
