//
//  GYM_APPApp.swift
//  GYM APP
//

import SwiftUI
import SwiftData
import OSLog

@main
struct GYM_APPApp: App {

    // Prevents the orphan sweep from running more than once per cold launch.
    // @State in App persists for the process lifetime.
    @State private var sweepDone = false

    // MARK: - Container initialization

    // Evaluated once at launch. Returns .failure instead of destroying data on error.
    // NEVER silently delete the user's store — show an error screen instead.
    private static let containerResult: Result<ModelContainer, Error> = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(
                for: Schema(GYMAppSchemaV1.models),
                migrationPlan: GYMAppMigrationPlan.self,
                configurations: [configuration]
            )
            FoodSeeder.seedIfNeeded(context: container.mainContext)
            AppLogger.persistence.info("ModelContainer ready — schema v1.0.0")
            return .success(container)
        } catch {
            // Log domain + code only — never log store URLs or user data.
            let nsError = error as NSError
            AppLogger.persistence.critical("ModelContainer init failed — domain: \(nsError.domain, privacy: .public), code: \(nsError.code, privacy: .public)")
            return .failure(error)
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            switch GYM_APPApp.containerResult {
            case .success(let container):
                MainTabView()
                    .modelContainer(container)
                    .task {
                        guard !sweepDone else { return }
                        sweepDone = true
                        PhotoOrphanSweepService.sweep(using: container.mainContext)
                    }
            case .failure:
                PersistenceErrorView()
            }
        }
    }
}
