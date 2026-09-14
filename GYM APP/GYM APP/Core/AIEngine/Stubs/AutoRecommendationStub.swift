//
//  AutoRecommendationStub.swift
//  GYM APP
//
//  Deterministic rule-based stub for AutoRecommendationServiceProtocol.
//  NOT a real AI model — produces fixed-category recommendations from
//  trend signals without any ML inference or network calls.
//  Safe for previews, tests, and demo builds.
//

import Foundation

struct AutoRecommendationStub: AutoRecommendationServiceProtocol {

    /// Injectable clock for deterministic timestamps in tests.
    let clock: @Sendable () -> Date

    init(clock: @Sendable @escaping () -> Date = { Date() }) {
        self.clock = clock
    }

    func generateRecommendations(
        athlete: AthleteSnapshot,
        statistics: AthleteStatisticsReport
    ) async throws -> [AIRecommendation] {
        guard statistics.checkInCount >= 2 else { return [] }

        var result: [AIRecommendation] = []
        let now = clock()

        // Body composition: rising fat trend with meaningful monthly delta (>0.3 pp/month)
        if statistics.bodyFatTrend.direction == .rising,
           statistics.bodyFatTrend.slope * 30 > 0.3 {
            result.append(AIRecommendation(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
                category: .bodyComposition,
                title: "Tendencia ascendente en grasa corporal",
                detail: "Los registros muestran un aumento sostenido de grasa corporal. Revisa el déficit calórico y la frecuencia de check-ins.",
                priority: .high,
                generatedAt: now
            ))
        }

        // Muscle mass: falling trend is a warning for a coach
        if statistics.muscleMassTrend.direction == .falling,
           statistics.muscleMassTrend.slope * 30 < -0.2 {
            result.append(AIRecommendation(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!,
                category: .bodyComposition,
                title: "Pérdida de masa muscular",
                detail: "Se detecta una tendencia a la baja en masa muscular. Considera revisar la ingesta proteica y la carga de entrenamiento.",
                priority: .high,
                generatedAt: now
            ))
        }

        // Check-in frequency: average gap > 21 days
        if let avg = statistics.averageDaysBetweenCheckIns, avg > 21 {
            result.append(AIRecommendation(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!,
                category: .checkInFrequency,
                title: "Baja frecuencia de check-ins",
                detail: String(format: "El promedio entre check-ins es %.0f días. Se recomienda una revisión cada 7–14 días.", avg),
                priority: .medium,
                generatedAt: now
            ))
        }

        return result.sorted { $0.priority > $1.priority }
    }
}
