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
//  To add a new version:
//  1. Define GYMAppSchemaV(N) with updated models.
//  2. Add a MigrationStage (lightweight or custom) between V(N-1) and V(N).
//  3. Append the new schema to GYMAppMigrationPlan.schemas.

import SwiftData

// MARK: - Schema V1.0.2

/// Current versioned schema (last bumped at Phase 39).
/// History of Optional additions (all lightweight — no migration plan needed):
///   v1.0.1 (Phase 37B): FoodImage gained imageOriginRaw, aiGenerationStateRaw
///   v1.0.2 (Phase 39):  FoodImage gained promptUsed (stores the prompt sent to the AI provider)
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
