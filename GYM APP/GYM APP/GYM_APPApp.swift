//
//  GYM_APPApp.swift
//  GYM APP
//

import SwiftUI
import SwiftData

@main
struct GYM_APPApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Athlete.self,
            CheckIn.self,
            BodyMetrics.self,
            CircumferenceMeasurements.self,
            SkinfoldMeasurements.self,
            ProgressPhoto.self,
            CoachNote.self,
            AthleteNote.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
