//
//  PhotoValidator.swift
//  GYM APP
//

import Foundation

/// Facade for progress photo validations.
enum PhotoValidator {

    static let maxFileSizeBytes: Int = 20 * 1_024 * 1_024    // 20 MB
    static let minDimensionPx: Int  = 100
    static let maxPhotosPerCheckIn: Int = 20

    static func validateFileSize(_ bytes: Int) -> ValidationResult {
        guard bytes <= maxFileSizeBytes else {
            let mb = maxFileSizeBytes / 1_024 / 1_024
            return .invalid(reason: "La foto no puede superar \(mb) MB.", severity: .error)
        }
        return .valid
    }

    static func validatePhotoCount(current: Int) -> ValidationResult {
        guard current < maxPhotosPerCheckIn else {
            return .invalid(
                reason: "No puedes agregar más de \(maxPhotosPerCheckIn) fotos por check-in.",
                severity: .error
            )
        }
        return .valid
    }

    static func validateDate(_ date: Date) -> ValidationResult {
        NotFutureDateRule(fieldName: "Fecha de la foto").validate(date)
    }
}
