//
//  NutritionPlanFormViewModel.swift
//  GYM APP
//

import Foundation
import SwiftData

@Observable
@MainActor
final class NutritionPlanFormViewModel {

    enum Mode {
        case create(Athlete)
        case edit(NutritionPlan)
    }

    // MARK: - Fields

    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date? = nil
    var hasEndDate: Bool = false
    var notes: String = ""

    var targetCaloriesText: String = ""
    var targetProteinText: String = ""
    var targetCarbsText: String = ""
    var targetFatText: String = ""
    var targetFiberText: String = ""

    // MARK: - State

    var isSaving: Bool = false
    var validationErrors: [String] = []

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - Private

    private let mode: Mode
    private let repository: NutritionPlanRepository

    init(mode: Mode, context: ModelContext) {
        self.mode = mode
        self.repository = NutritionPlanRepository(context: context)
        if case .edit(let plan) = mode { loadFields(from: plan) }
    }

    // MARK: - Save

    func save() throws {
        var errors: [String] = []
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty { errors.append("El nombre del plan es requerido.") }
        validationErrors = errors
        guard errors.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let end: Date?    = hasEndDate ? endDate : nil
        let notesVal: String? = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil
                                : notes.trimmingCharacters(in: .whitespaces)
        let kcal  = Double(targetCaloriesText)
        let prot  = Double(targetProteinText)
        let carbs = Double(targetCarbsText)
        let fat   = Double(targetFatText)
        let fiber = Double(targetFiberText)

        switch mode {
        case .create(let athlete):
            let plan = try repository.add(name: trimmedName, startDate: startDate, to: athlete)
            try repository.update(plan, name: trimmedName, startDate: startDate, endDate: end,
                                  notes: notesVal, targetCalories: kcal, targetProtein: prot,
                                  targetCarbohydrates: carbs, targetFat: fat, targetFiber: fiber)
        case .edit(let plan):
            try repository.update(plan, name: trimmedName, startDate: startDate, endDate: end,
                                  notes: notesVal, targetCalories: kcal, targetProtein: prot,
                                  targetCarbohydrates: carbs, targetFat: fat, targetFiber: fiber)
        }
    }

    // MARK: - Load

    private func loadFields(from plan: NutritionPlan) {
        name      = plan.name
        startDate = plan.startDate
        if let end = plan.endDate {
            endDate    = end
            hasEndDate = true
        }
        notes              = plan.notes ?? ""
        targetCaloriesText = plan.targetCalories.map      { fmt($0) } ?? ""
        targetProteinText  = plan.targetProtein.map       { fmt($0) } ?? ""
        targetCarbsText    = plan.targetCarbohydrates.map { fmt($0) } ?? ""
        targetFatText      = plan.targetFat.map           { fmt($0) } ?? ""
        targetFiberText    = plan.targetFiber.map         { fmt($0) } ?? ""
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }
}
