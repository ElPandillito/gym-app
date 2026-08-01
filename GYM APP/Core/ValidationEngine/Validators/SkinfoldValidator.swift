//
//  SkinfoldValidator.swift
//  GYM APP
//

import Foundation

/// Facade for skinfold measurement validations.
enum SkinfoldValidator {

    static func validateSite(_ mm: Double?, name: String) -> ValidationResult {
        OptionalNumericRangeRule(
            min: PhysiologicalRanges.Skinfold.min,
            max: PhysiologicalRanges.Skinfold.max,
            fieldName: name
        ).validate(mm)
    }

    /// Validates that the required sites for a given method + gender are all present and in range.
    static func validateRequiredSites(
        method: PlicometryMethod,
        gender: Gender,
        inputs: SkinfoldInputs
    ) -> ValidationReport {
        let sites: [(Double?, String)] = requiredSites(method: method, gender: gender, inputs: inputs)
        let results = sites.flatMap { (value, name) -> [ValidationResult] in
            if value == nil {
                return [.invalid(reason: "\(name) es obligatorio para \(method.displayName).", severity: .error)]
            }
            return [validateSite(value, name: name)]
        }
        return ValidationReport(results: results)
    }

    private static func requiredSites(
        method: PlicometryMethod,
        gender: Gender,
        inputs: SkinfoldInputs
    ) -> [(Double?, String)] {
        switch method {
        case .jacksonPollockThree:
            if gender == .female {
                return [(inputs.tricep, "Trícep"), (inputs.suprailiac, "Suprailíaco"), (inputs.thigh, "Muslo")]
            }
            return [(inputs.chest, "Pecho"), (inputs.abdomen, "Abdomen"), (inputs.thigh, "Muslo")]
        case .jacksonPollockSeven:
            return [
                (inputs.chest, "Pecho"), (inputs.midaxillary, "Axilar medio"),
                (inputs.tricep, "Trícep"), (inputs.subscapular, "Subescapular"),
                (inputs.abdomen, "Abdomen"), (inputs.suprailiac, "Suprailíaco"), (inputs.thigh, "Muslo")
            ]
        case .durninWomersley:
            return [
                (inputs.bicep, "Bícep"), (inputs.tricep, "Trícep"),
                (inputs.subscapular, "Subescapular"), (inputs.suprailiac, "Suprailíaco")
            ]
        case .parrillo:
            return [
                (inputs.chest, "Pecho"), (inputs.abdomen, "Abdomen"), (inputs.thigh, "Muslo"),
                (inputs.bicep, "Bícep"), (inputs.tricep, "Trícep"),
                (inputs.subscapular, "Subescapular"), (inputs.suprailiac, "Suprailíaco"),
                (inputs.lowerBack, "Lumbar"), (inputs.calf, "Pantorrilla")
            ]
        case .custom:
            return []
        }
    }
}
