//
//  FoodValidator.swift
//  GYM APP
//

import Foundation

/// Validates food domain inputs using the existing ValidationEngine conventions.
enum FoodValidator {

    struct ValidationError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    // MARK: - Food fields

    static func validateName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw ValidationError(message: "El nombre del alimento es requerido.")
        }
        guard trimmed.count >= 2 else {
            throw ValidationError(message: "El nombre debe tener al menos 2 caracteres.")
        }
        guard trimmed.count <= 120 else {
            throw ValidationError(message: "El nombre no puede superar 120 caracteres.")
        }
    }

    /// Validates a single macro value (kcal or grams) expressed per 100 g.
    static func validateMacro(_ value: Double?, fieldName: String) throws {
        guard let v = value else { return }
        guard v >= 0 else {
            throw ValidationError(message: "\(fieldName) no puede ser negativo.")
        }
        guard v <= 900 else {
            throw ValidationError(message: "\(fieldName) por 100 g no puede superar 900.")
        }
    }

    static func validateServingSize(_ size: Double?) throws {
        guard let s = size else { return }
        guard s > 0 else {
            throw ValidationError(message: "La porción debe ser mayor a 0.")
        }
        guard s <= 5_000 else {
            throw ValidationError(message: "La porción no puede superar 5,000 g.")
        }
    }

    // MARK: - RecipeIngredient fields

    static func validateAmountGrams(_ amount: Double) throws {
        guard amount > 0 else {
            throw ValidationError(message: "La cantidad debe ser mayor a 0 g.")
        }
        guard amount <= 10_000 else {
            throw ValidationError(message: "La cantidad no puede superar 10,000 g.")
        }
    }

    // MARK: - Composite validation

    /// Validates all editable fields of a food form.
    /// Returns every error message so the UI can display them all at once.
    static func validate(
        name: String,
        calories: Double?,
        protein: Double?,
        carbohydrates: Double?,
        fat: Double?,
        fiber: Double?,
        servingSize: Double?
    ) -> [String] {
        var errors: [String] = []

        func collect(_ block: () throws -> Void) {
            do { try block() } catch { errors.append(error.localizedDescription) }
        }

        collect { try validateName(name) }
        collect { try validateMacro(calories,      fieldName: "Calorías") }
        collect { try validateMacro(protein,       fieldName: "Proteína") }
        collect { try validateMacro(carbohydrates, fieldName: "Carbohidratos") }
        collect { try validateMacro(fat,           fieldName: "Grasa") }
        collect { try validateMacro(fiber,         fieldName: "Fibra") }
        collect { try validateServingSize(servingSize) }

        return errors
    }
}
