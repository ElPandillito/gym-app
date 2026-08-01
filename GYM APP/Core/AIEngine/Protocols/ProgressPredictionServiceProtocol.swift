//
//  ProgressPredictionServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for ML-based progress prediction.
protocol ProgressPredictionServiceProtocol {
    /// Predicts metric values N days into the future given historical snapshots.
    func predict(
        metric: MetricKey,
        snapshots: [CheckInSnapshot],
        daysAhead: Int
    ) async throws -> PredictionResult
}

struct PredictionResult: Sendable {
    let metric: MetricKey
    let predictedValue: Double
    let confidenceInterval: ClosedRange<Double>
    let targetDate: Date
    let modelConfidence: Double     // 0.0 – 1.0
}
