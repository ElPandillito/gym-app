//
//  Trend.swift
//  GYM APP
//

import Foundation

/// Linear trend computed over a series of DataPoints.
struct Trend: Equatable, Sendable {
    let slope: Double           // Units per day
    let intercept: Double
    let dataPointCount: Int
    let direction: TrendDirection

    enum TrendDirection: Equatable {
        case rising
        case falling
        case flat
        case insufficient       // < 2 data points
    }

    static let insufficient = Trend(slope: 0, intercept: 0, dataPointCount: 0, direction: .insufficient)

    /// Projects the value at a given date using the linear model.
    func projected(at date: Date, origin: Date) -> Double {
        let days = date.timeIntervalSince(origin) / 86_400
        return intercept + slope * days
    }
}

// MARK: - Trend computation (Ordinary Least Squares)

extension Trend {
    static func compute(from points: [DataPoint]) -> Trend {
        guard points.count >= 2 else {
            return .insufficient
        }
        let sorted  = points.sorted { $0.date < $1.date }
        let origin  = sorted.first!.date
        let xs      = sorted.map { $0.date.timeIntervalSince(origin) / 86_400 }
        let ys      = sorted.map { $0.value }
        let n       = Double(xs.count)
        let sumX    = xs.reduce(0, +)
        let sumY    = ys.reduce(0, +)
        let sumXY   = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX   = xs.reduce(0) { $0 + $1 * $1 }
        let denom   = n * sumXX - sumX * sumX
        guard abs(denom) > 1e-10 else {
            return Trend(slope: 0, intercept: sumY / n, dataPointCount: sorted.count, direction: .flat)
        }
        let slope     = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n
        let direction: Trend.TrendDirection = abs(slope) < 0.001 ? .flat : slope > 0 ? .rising : .falling
        return Trend(slope: slope, intercept: intercept, dataPointCount: sorted.count, direction: direction)
    }
}
