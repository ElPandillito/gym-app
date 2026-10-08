//
//  AppSchema.swift
//  GYM APP
//
//  Defines the versioned SwiftData schema and migration plan.
//
//  MIGRATION RULES:
//  - Adding Optional fields → lightweight migration, increment patch version.
//  - Adding Non-Optional fields → requires custom stage + default value.
//  - Removing or renaming fields → requires custom migration stage.
//  - NEVER wipe the store to recover from schema errors.
//
//  To add a new schema version:
//  • Optional fields only: bump versionIdentifier (patch) in GYMAppSchemaV1 and add
//    the property to the @Model class. SwiftData infers the migration automatically.
//    No migration plan or new schema enum is needed.
//  • Non-Optional fields, renames, or deletions: introduce GYMAppSchemaV2 with the
//    updated model list, declare a GYMAppMigrationPlan with explicit stages, and
//    update ModelContainer in GYM_APPApp.swift to pass migrationPlan:.

import SwiftData

// MARK: - Schema V1.0.2

/// Current versioned schema (last bumped at Phase 39).
/// History of Optional additions (all lightweight — no migration plan needed):
///   v1.0.1 (Phase 37B): FoodImage gained imageOriginRaw, aiGenerationStateRaw
///   v1.0.2 (Phase 39):  FoodImage gained promptUsed (stores the prompt sent to the AI provider)
///   v1.0.2 (undocumented at the time): NutritionPlan gained targetCalories, targetProtein,
///     targetCarbohydrates, targetFat, targetFiber — added without a version bump. Documented
///     retroactively here at Phase 50; no new fields were introduced in that phase.
enum GYMAppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 2)

    static var models: [any PersistentModel.Type] {
        [
            Athlete.self,
            CheckIn.self,
            BodyMetrics.self,
            CircumferenceMeasurements.self,
            SkinfoldMeasurements.self,
            ISAKBreadthsMeasurements.self,
            ISAKLengthsMeasurements.self,
            ProgressPhoto.self,
            CoachNote.self,
            AthleteNote.self,
            AIBodyFatAssessment.self,
            Food.self,
            FoodImage.self,
            RecipeIngredient.self,
            NutritionPlan.self,
            Meal.self,
            MealItem.self,
        ]
    }
}
