//
//  BodyFatAssessmentStub.swift
//  GYM APP
//
//  Deterministic rule-based stub for BodyFatAssessmentServiceProtocol.
//  No computer vision is performed — estimates are derived from available
//  anthropometric data in priority order:
//
//    1. Skinfold plicometry body fat %   (highest-quality proxy, confidence ≤ 0.55)
//    2. Bioimpedance body fat %          (good proxy, confidence ≤ 0.50)
//    3. U.S. Navy circumference formula  (waist, hip, neck, height, confidence ≤ 0.40)
//    4. Deurenberg BMI formula           (weight, height, age, gender, confidence ≤ 0.30)
//
//  If no signal is available, throws AIServiceError.insufficientData.
//  Confidence is never above 0.55 — this stub never simulates vision reliability.
//
//  Photo presence adds a small bonus (≤ 0.05) to acknowledge that the future
//  vision implementation will use those paths.
//

import Foundation

struct BodyFatAssessmentStub: BodyFatAssessmentServiceProtocol {

    let clock: @Sendable () -> Date

    init(clock: @Sendable @escaping () -> Date = { Date() }) {
        self.clock = clock
    }

    func estimate(
        photos: [PhotoPathEntry],
        context: BodyFatAssessmentContext
    ) async throws -> BodyFatAssessmentResult {

        var estimatedBF: Double
        var baseConfidence: Double
        var notes: [String] = []

        // Priority 1 — Skinfold plicometry
        if let sf = context.skinfoldBodyFatPct {
            guard (3.0...60.0).contains(sf) else {
                throw AIServiceError.invalidInput("skinfoldBodyFatPct out of physiological range")
            }
            estimatedBF = sf
            baseConfidence = 0.55
            notes.append("Estimación basada en plicometría (dato directo de mayor precisión).")

        // Priority 2 — Bioimpedance
        } else if let bio = context.bioimpedanceBodyFatPct {
            guard (3.0...60.0).contains(bio) else {
                throw AIServiceError.invalidInput("bioimpedanceBodyFatPct out of physiological range")
            }
            estimatedBF = bio
            baseConfidence = 0.50
            notes.append("Estimación basada en bioimpedancia eléctrica (báscula de composición corporal).")

        // Priority 3 — U.S. Navy circumference formula
        } else if let waist = context.waistCm,
                  let hip   = context.hipCm,
                  let h     = context.heightCm,
                  let g     = context.gender,
                  h > 0, waist > 0, hip > 0 {

            estimatedBF = navyFormula(
                waistCm: waist, hipCm: hip,
                neckCm: context.neckCm ?? (waist * 0.22),   // fallback estimate for neck
                heightCm: h, gender: g
            )
            baseConfidence = context.neckCm != nil ? 0.40 : 0.32
            notes.append("Estimación por fórmula de la Marina Americana (circunferencias corporales).")
            if context.neckCm == nil {
                notes.append("Cuello no registrado — se usó valor estimado, reduciendo precisión.")
            }

        // Priority 4 — Deurenberg BMI formula
        } else if let kg  = context.bodyWeightKg,
                  let h   = context.heightCm,
                  let g   = context.gender,
                  h > 0, kg > 0 {

            let age = context.ageYears ?? 30.0
            let bmi = kg / pow(h / 100.0, 2)
            estimatedBF = deurenbergFormula(bmi: bmi, gender: g, ageYears: age)
            baseConfidence = 0.30
            notes.append("Estimación por fórmula de Deurenberg (peso, estatura, género, edad).")
            notes.append("Precisión limitada — considera registrar medidas de composición corporal.")

        } else {
            throw AIServiceError.insufficientData
        }

        // Clamp to physiological range
        estimatedBF = min(max(estimatedBF, 3.0), 60.0)

        // Photo presence bonus — acknowledges that the real model will use them
        let photoBonus = photoConfidenceBonus(photos: photos)
        let finalConfidence = min(0.55, baseConfidence + photoBonus)

        if !photos.isEmpty {
            let poseNames = photos.map(\.poseType.displayName).joined(separator: ", ")
            notes.append("Fotos disponibles (\(photos.count)): \(poseNames). Un modelo de visión por computadora podrá mejorar esta estimación.")
        }

        notes.append("Esta estimación es determinística y no procesa imágenes. Es una aproximación basada en los datos registrados.")

        return BodyFatAssessmentResult(
            estimatedBodyFatPct: (estimatedBF * 10).rounded() / 10,
            confidenceScore:     finalConfidence,
            assessmentBasis:     .stubDeterministic,
            notes:               notes,
            generatedAt:         clock()
        )
    }

    // MARK: - Formulas

    /// U.S. Navy circumference formula (Jackson & Pollock adaptation).
    private func navyFormula(
        waistCm: Double, hipCm: Double, neckCm: Double, heightCm: Double, gender: Gender
    ) -> Double {
        switch gender {
        case .female:
            let num = waistCm + hipCm - neckCm
            guard num > 0 else { return 25.0 }
            return 163.205 * log10(num) - 97.684 * log10(heightCm) - 78.387
        case .male, .other:
            let diff = waistCm - neckCm
            guard diff > 0 else { return 18.0 }
            return 86.010 * log10(diff) - 70.041 * log10(heightCm) + 36.76
        }
    }

    /// Deurenberg et al. (1991) BMI-based body fat formula.
    private func deurenbergFormula(bmi: Double, gender: Gender, ageYears: Double) -> Double {
        let sexFactor: Double = (gender == .female) ? 0.0 : 1.0
        return 1.20 * bmi + 0.23 * ageYears - 10.8 * sexFactor - 5.4
    }

    /// Small confidence bonus for having photos available (future vision model will use them).
    private func photoConfidenceBonus(photos: [PhotoPathEntry]) -> Double {
        guard !photos.isEmpty else { return 0.0 }
        let poses = Set(photos.map(\.poseType))
        let hasFront = poses.contains(.frontRelaxed) || poses.contains(.frontDoubleBiceps)
        let hasBack  = poses.contains(.backRelaxed)  || poses.contains(.backDoubleBiceps)
        let hasSide  = poses.contains(.sideChestLeft)  || poses.contains(.sideChestRight)
                    || poses.contains(.sideTricepsLeft) || poses.contains(.sideTricepsRight)
        let coverageScore = [hasFront, hasBack, hasSide].filter { $0 }.count
        switch coverageScore {
        case 3:    return 0.05
        case 2:    return 0.03
        default:   return 0.01
        }
    }
}
