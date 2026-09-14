//
//  PhotoOrphanSweepService.swift
//  GYM APP
//

import SwiftData
import OSLog

/// Cold-launch orphan sweep for progress-photo filesystem artifacts.
///
/// Fetches every ProgressPhoto from SwiftData and builds the set of valid
/// relative paths (original + thumbnail). Any .jpg file under the Athletes/
/// photo root that is NOT in that set is treated as an orphan and deleted.
///
/// Typical orphan source: a CheckIn save() that wrote Phase B files but
/// crashed before Phase D commit, leaving the compensation block unrun.
///
/// Safety contract:
///   - Fails closed: if the SwiftData fetch fails, no files are deleted.
///   - Restricted to the Athletes/ root; other Documents/ content is never touched.
///   - Logs aggregate counts only — never logs paths, IDs, or athlete data.
///   - Idempotent: safe to call more than once (e.g., on retry after prior error).
struct PhotoOrphanSweepService {

    /// Runs the sweep synchronously on the caller's actor.
    /// Must be called on @MainActor because it accesses ModelContainer.mainContext.
    static func sweep(using context: ModelContext) {
        do {
            // Fail closed — if persistence is unavailable, skip all destructive work.
            let descriptor = FetchDescriptor<ProgressPhoto>()
            let photos = try context.fetch(descriptor)

            var knownPaths = Set<String>()
            knownPaths.reserveCapacity(photos.count * 2)
            for photo in photos {
                knownPaths.insert(photo.originalPath)
                if let thumb = photo.thumbnailPath { knownPaths.insert(thumb) }
            }

            let storage = PhotoStorageService()
            let removed = storage.sweepOrphanFiles(knownRelativePaths: knownPaths)

            if removed > 0 {
                AppLogger.storage.info("Photo orphan sweep completed — removed \(removed) orphan file(s)")
            }
        } catch {
            // Fail closed — do NOT proceed with deletions if we cannot confirm what is valid.
            AppLogger.storage.warning("Photo orphan sweep skipped — SwiftData fetch unavailable")
        }
    }
}
