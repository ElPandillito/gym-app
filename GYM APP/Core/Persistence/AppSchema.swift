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
//  1. Define GYMAppSchemaV2 with updated models.
//  2. Add a MigrationStage (lightweight or custom) between V1 and V2.
//  3. Append GYMAppSchemaV2 to GYMAppMigrationPlan.schemas.

import SwiftData

// MARK: - Schema V1.0.0

/// The canonical first versioned schema. Established at app version 1.0 (Phase 21).
/// All prior @Model changes used automatic lightweight migration (all new fields were Optional).
enum GYMAppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

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

// MARK: - Migration Plan

/// Ordered list of schema versions (oldest → newest) with migration stages between them.
/// Currently a single version; no stages needed yet.
enum GYMAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [GYMAppSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
