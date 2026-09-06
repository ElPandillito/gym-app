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
    @State private var preferencesStore = CoachPreferencesStore()

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
            applyStoreProtection(to: configuration.url)   // D2: FileProtection + no-backup
            AppLogger.persistence.info("ModelContainer ready — schema v1.0.0")
            return .success(container)
        } catch {
            // Log domain + code only — never log store URLs or user data.
            let nsError = error as NSError
            AppLogger.persistence.critical("ModelContainer init failed — domain: \(nsError.domain, privacy: .public), code: \(nsError.code, privacy: .public)")
            return .failure(error)
        }
    }()

    /// Applies FileProtection.completeUnlessOpen and excludes from iCloud backup
    /// on the SwiftData store and its WAL/SHM auxiliary files.
    /// Uses try? — failures are best-effort; they don't compromise data integrity.
    private static func applyStoreProtection(to url: URL) {
        let dir  = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let candidates: [URL] = [
            url,
            dir.appendingPathComponent(stem + ".sqlite"),
            dir.appendingPathComponent(stem + ".sqlite-shm"),
            dir.appendingPathComponent(stem + ".sqlite-wal"),
        ]
        for candidate in candidates {
            guard FileManager.default.fileExists(atPath: candidate.path) else { continue }
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUnlessOpen],
                ofItemAtPath: candidate.path
            )
            var rv = URLResourceValues()
            rv.isExcludedFromBackup = true
            var mutable = candidate
            try? mutable.setResourceValues(rv)
        }
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            switch GYM_APPApp.containerResult {
            case .success(let container):
                MainTabView()
                    .modelContainer(container)
                    .environment(preferencesStore)
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
