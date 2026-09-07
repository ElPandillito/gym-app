//
//  ProgressPredictionStub.swift
//  GYM APP
//
//  Deterministic OLS-based prediction stub for ProgressPredictionServiceProtocol.
//  Uses the same Trend.compute / Trend.projected math as StatisticsEngine.
//  NOT an ML model — purely linear extrapolation from historical data.
//  Confidence is capped at 0.80 to never imply high certainty.
//

import Foundation

struct ProgressPredictionStub: ProgressPredictionServiceProtocol {

    func predict(
        metric: MetricKey,
        snapshots: [CheckInSnapshot],
        daysAhead: Int
    ) async throws -> PredictionResult {
        guard daysAhead > 0 else {
            throw AIServiceError.invalidInput("daysAhead must be > 0")
        }

        let points = extractPoints(metric: metric, from: snapshots)
        guard points.count >= 2 else {
            throw AIServiceError.insufficientData
        }

        let sorted = points.sorted { $0.date < $1.date }
        let origin = sorted[0].date
        let trend  = Trend.compute(from: sorted)

        guard trend.direction != .insufficient else {
            throw AIServiceError.insufficientData
        }

        let latestDate = sorted[sorted.count - 1].date
        let targetDate = latestDate.addingTimeInterval(Double(daysAhead) * 86_400)
        let predicted  = trend.projected(at: targetDate, origin: origin)

        // Residual standard error — grows with prediction horizon.
        let residuals = sorted.map { $0.value - trend.projected(at: $0.date, origin: origin) }
        let mse       = residuals.map { $0 * $0 }.reduce(0, +) / Double(max(residuals.count - 2, 1))
        let stdErr    = sqrt(mse) * (1.0 + Double(daysAhead) / 30.0)

        // Cap confidence: more data = more confident, but never above 0.80 (we're a stub, not ML).
        let confidence = min(0.80, Double(points.count) / 10.0)

        return PredictionResult(
            metric: metric,
            predictedValue: predicted,
            confidenceInterval: (predicted - stdErr) ... (predicted + stdErr),
            targetDate: targetDate,
            modelConfidence: confidence
        )
    }

    // MARK: - Private

    private func extractPoints(metric: MetricKey, from snapshots: [CheckInSnapshot]) -> [DataPoint] {
        snapshots.compactMap { snap in
            let value: Double? = switch metric {
            case .weight:          snap.bodyMetrics?.bodyWeight
            case .bmi:             snap.bodyMetrics?.bmi
            case .bodyFat:         snap.bodyMetrics?.bodyFatPercentage
            case .muscleMass:      snap.bodyMetrics?.muscleMass
            case .boneMass:        snap.bodyMetrics?.boneMass
            case .water:           snap.bodyMetrics?.waterPercentage
            case .visceralFat:     snap.bodyMetrics?.visceralFatLevel
            case .bmr:             snap.bodyMetrics?.basalMetabolicRate
            case .skinfoldBodyFat: snap.skinfolds?.estimatedBodyFatPercentage
            }
            return value.map { DataPoint(date: snap.date, value: $0) }
        }
    }
}
