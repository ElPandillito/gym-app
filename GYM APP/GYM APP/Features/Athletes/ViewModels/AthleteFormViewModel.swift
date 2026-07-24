//
//  AthleteFormViewModel.swift
//  GYM APP
//

import SwiftUI

@Observable
final class AthleteFormViewModel {
    var name: String = ""
    var gender: Gender = .other
    var heightText: String = ""
    var hasBirthDate: Bool = false
    var birthDate: Date = Date()

    var nameError: String? = nil
    var heightError: String? = nil

    private let existingAthlete: Athlete?

    var isEditing: Bool { existingAthlete != nil }
    var title: String { isEditing ? "Editar Atleta" : "Nuevo Atleta" }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && nameError == nil
            && heightError == nil
    }

    init(athlete: Athlete? = nil) {
        self.existingAthlete = athlete
        if let athlete {
            name       = athlete.name
            gender     = athlete.gender
            hasBirthDate = athlete.birthDate != nil
            birthDate  = athlete.birthDate ?? Date()
            heightText = athlete.height.map { String(format: "%.1f", $0) } ?? ""
        }
    }

    func validateName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        nameError = trimmed.isEmpty ? "El nombre es obligatorio." : nil
    }

    func validateHeight() {
        guard !heightText.isEmpty else { heightError = nil; return }
        if let value = Double(heightText.replacingOccurrences(of: ",", with: ".")) {
            heightError = value <= 0 ? "La estatura debe ser mayor a 0." : nil
        } else {
            heightError = "Ingresa un número válido."
        }
    }

    // Returns true on success
    func save(using repository: AthleteRepository) -> Bool {
        validateName()
        validateHeight()
        guard canSave else { return false }

        let parsedHeight: Double? = {
            guard !heightText.isEmpty else { return nil }
            return Double(heightText.replacingOccurrences(of: ",", with: "."))
        }()

        if let athlete = existingAthlete {
            athlete.name      = name.trimmingCharacters(in: .whitespaces)
            athlete.gender    = gender
            athlete.birthDate = hasBirthDate ? birthDate : nil
            athlete.height    = parsedHeight
            try? repository.update(athlete)
        } else {
            let athlete = Athlete(
                name: name.trimmingCharacters(in: .whitespaces),
                gender: gender,
                birthDate: hasBirthDate ? birthDate : nil,
                height: parsedHeight
            )
            try? repository.add(athlete)
        }
        return true
    }
}
