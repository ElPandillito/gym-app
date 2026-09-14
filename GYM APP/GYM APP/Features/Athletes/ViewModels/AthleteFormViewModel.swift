//
//  AthleteFormViewModel.swift
//  GYM APP
//

import SwiftUI
import OSLog

@MainActor @Observable
final class AthleteFormViewModel {
    var name: String         = ""
    var gender: Gender       = .other
    var phase: AthletePhase  = .offSeason
    var heightText: String   = ""
    var hasBirthDate: Bool   = false
    var birthDate: Date      = Date()

    var nameError: String?   = nil
    var heightError: String? = nil
    var saveError: String?   = nil

    private let existingAthlete: Athlete?
    private var preferences: CoachPreferences = .default

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
            name         = athlete.name
            gender       = athlete.gender
            phase        = athlete.phase
            hasBirthDate = athlete.birthDate != nil
            birthDate    = athlete.birthDate ?? Date()
            heightText   = athlete.height.map { String(format: "%.1f", $0) } ?? ""
        }
    }

    // MARK: - Apply preferences (call once from onAppear)

    /// Stores preferences and re-formats heightText from canonical cm to display units.
    func apply(preferences: CoachPreferences) {
        self.preferences = preferences
        guard let h = existingAthlete?.height else { return }
        heightText = String(format: "%.1f", AppUnitFormatter(preferences: preferences).convertedLength(h))
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

    // Returns true on success. Exposes saveError for the UI.
    func save(using repository: AthleteRepository) -> Bool {
        validateName()
        validateHeight()
        guard canSave else { return false }
        saveError = nil

        let fmt = AppUnitFormatter(preferences: preferences)
        let parsedHeight: Double? = {
            guard !heightText.isEmpty else { return nil }
            guard let v = Double(heightText.replacingOccurrences(of: ",", with: ".")) else { return nil }
            return fmt.toCanonicalLength(v)
        }()

        do {
            if let athlete = existingAthlete {
                athlete.name      = name.trimmingCharacters(in: .whitespaces)
                athlete.gender    = gender
                athlete.phase     = phase
                athlete.birthDate = hasBirthDate ? birthDate : nil
                athlete.height    = parsedHeight
                try repository.update(athlete)
            } else {
                let athlete = Athlete(
                    name:      name.trimmingCharacters(in: .whitespaces),
                    gender:    gender,
                    birthDate: hasBirthDate ? birthDate : nil,
                    height:    parsedHeight,
                    phase:     phase
                )
                try repository.add(athlete)
            }
            return true
        } catch {
            saveError = "No se pudo guardar el atleta. Inténtalo de nuevo."
            AppLogger.persistence.error("AthleteFormViewModel save failed")
            return false
        }
    }
}
