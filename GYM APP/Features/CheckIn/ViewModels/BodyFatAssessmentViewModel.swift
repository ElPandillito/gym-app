//
//  BodyFatAssessmentViewModel.swift
//  GYM APP
//

import SwiftUI
import SwiftData

@MainActor @Observable
final class BodyFatAssessmentViewModel {

    enum State {
        case idle
        case loading
        case result(AIBodyFatAssessment)
        case error(String)
    }

    private(set) var state: State = .idle

    private let service: any BodyFatAssessmentServiceProtocol

    init(service: any BodyFatAssessmentServiceProtocol = BodyFatAssessmentStub()) {
        self.service = service
    }

    /// Loads an existing assessment from a check-in without running the service.
    func loadExisting(from checkIn: CheckIn) {
        if let existing = checkIn.aiBodyFatAssessment {
            state = .result(existing)
        }
    }

    func run(for checkIn: CheckIn, context: ModelContext) {
        guard case .idle = state else { return }
        state = .loading

        let photos = checkIn.photos.map {
            PhotoPathEntry(relativePath: $0.originalPath, poseType: $0.poseType)
        }

        let athlete   = checkIn.athlete
        let metrics   = checkIn.bodyMetrics
        let circs     = checkIn.circumferences
        let skinfolds = checkIn.skinfolds

        let age: Double? = athlete?.birthDate.map { bd in
            let comps = Calendar.current.dateComponents([.year], from: bd, to: Date())
            return Double(comps.year ?? 25)
        }

        let assessmentContext = BodyFatAssessmentContext(
            bodyWeightKg:            metrics?.bodyWeight,
            heightCm:                athlete?.height,
            bioimpedanceBodyFatPct:  metrics?.bodyFatPercentage,
            skinfoldBodyFatPct:      skinfolds?.estimatedBodyFatPercentage,
            waistCm:                 circs?.waist,
            hipCm:                   circs?.hips,
            neckCm:                  circs?.neck,
            gender:                  athlete?.gender,
            ageYears:                age
        )

        Task {
            do {
                let result = try await service.estimate(photos: photos, context: assessmentContext)
                let model = AIBodyFatAssessment(
                    estimatedBodyFatPct: result.estimatedBodyFatPct,
                    confidenceScore:     result.confidenceScore,
                    assessmentBasis:     result.assessmentBasis,
                    notes:               result.notes,
                    photoCount:          photos.count,
                    generatedAt:         result.generatedAt
                )
                let repository = AIBodyFatAssessmentRepository(context: context)
                try repository.save(model, for: checkIn)
                state = .result(model)
            } catch AIServiceError.insufficientData {
                state = .error("Datos insuficientes. Registra peso, circunferencias o pliegues cutáneos para obtener una estimación.")
            } catch AIServiceError.invalidInput(let msg) {
                state = .error("Datos fuera de rango: \(msg)")
            } catch {
                state = .error("No se pudo completar la estimación. Inténtalo de nuevo.")
            }
        }
    }

    func reset() {
        state = .idle
    }
}
