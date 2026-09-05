//
//  CheckInWorkflowViewModel.swift
//  GYM APP
//

import SwiftUI
import SwiftData
import OSLog

// MARK: - Step

enum CheckInWorkflowStep: Int, CaseIterable, Identifiable {
    case metricas
    case circunferencias
    case plicometria
    case diametros       // ISAK breadths/depths — shown for isak profiles
    case longitudes      // ISAK lengths/heights — shown for Level 2 only
    case fotos
    case notas
    case revision

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .metricas:        return "Métricas"
        case .circunferencias: return "Circunferencias"
        case .plicometria:     return "Plicometría"
        case .diametros:       return "Diámetros"
        case .longitudes:      return "Longitudes"
        case .fotos:           return "Fotos"
        case .notas:           return "Notas"
        case .revision:        return "Revisión"
        }
    }

    var icon: String {
        switch self {
        case .metricas:        return "scalemass.fill"
        case .circunferencias: return "arrow.left.and.right.circle.fill"
        case .plicometria:     return "ruler.fill"
        case .diametros:       return "arrow.left.and.right"
        case .longitudes:      return "arrow.up.and.down.circle"
        case .fotos:           return "camera.fill"
        case .notas:           return "note.text"
        case .revision:        return "checkmark.circle.fill"
        }
    }
}

// MARK: - Photo draft (in-memory, not persisted until save)

struct PhotoDraft: Identifiable {
    let id: UUID     = UUID()
    let data: Data
    var poseType:    PoseType
    var capturedAt:  Date
    var notes:       String?
}

// MARK: - ViewModel

/// Orchestrates the check-in creation workflow.
/// All data lives in memory until save() is called.
///
/// Save strategy (Phase 21C — compensating transaction):
///
///   Phase B — Filesystem writes:
///     Photo files are written before any SwiftData inserts.
///     Each written path is appended to a rollback journal.
///
///   Phase C — SwiftData inserts (no save):
///     All objects are inserted into the context but context.save() is deferred.
///
///   Phase D — Single commit:
///     context.save() is the only commit in the entire workflow.
///
///   On any failure — Compensation:
///     context.rollback() undoes all pending inserts.
///     The rollback journal deletes exactly the photo files created this attempt.
///     Preexisting photos are never touched.
///     savedCheckIn remains nil. Workflow stays in memory for retry.
///
/// Note: filesystem + SwiftData do NOT form an ACID-distributed transaction.
/// This is a compensating transaction, not atomic rollback.
@Observable
@MainActor
final class CheckInWorkflowViewModel {

    // MARK: - Context
    let athlete: Athlete

    // MARK: - Anthropometry profile
    var anthropometryProfile: AnthropometryProfile = .standard

    // MARK: - Navigation
    var currentStep: CheckInWorkflowStep = .metricas
    var isShowingPhotoForm              = false

    // MARK: - Date (shown in header across all steps)
    var date: Date = Date()

    // MARK: - Sub-ViewModels
    var bodyMetrics:    BodyMetricsViewModel
    var circumferences: CircumferenceMeasurementsViewModel
    var skinfolds:      SkinfoldMeasurementsViewModel
    var extended:       AnthropometryExtendedViewModel

    // MARK: - Photos (in-memory — no file I/O until final save)

    // Non-negotiable limits — enforced regardless of UI state.
    static let maxPhotosPerCheckIn  = 20
    private static let maxPhotoDraftBytes = 10 * 1024 * 1024  // 10 MB

    var photoDrafts:  [PhotoDraft] = []
    var photoAddError: String?     = nil

    var canAddPhoto: Bool { photoDrafts.count < Self.maxPhotosPerCheckIn }

    // MARK: - Notes
    var coachNoteText:   String = ""
    var athleteNoteText: String = ""

    // MARK: - Save state
    var isSaving:     Bool      = false
    var saveError:    String?   = nil
    var savedCheckIn: CheckIn?  = nil

    // MARK: - Init

    init(athlete: Athlete) {
        self.athlete = athlete
        let height   = athlete.height
        let gender   = athlete.gender
        let age      = athlete.birthDate.map(Self.ageInYears) ?? 25.0

        self.bodyMetrics    = BodyMetricsViewModel(metrics: nil, athleteHeight: height)
        self.circumferences = CircumferenceMeasurementsViewModel(measurements: nil)
        self.skinfolds      = SkinfoldMeasurementsViewModel(
            measurements: nil,
            gender:       gender,
            age:          age,
            bodyWeightKg: nil
        )
        self.extended = AnthropometryExtendedViewModel()
    }

    // MARK: - Active steps (profile-aware)

    var activeSteps: [CheckInWorkflowStep] {
        var steps: [CheckInWorkflowStep] = [.metricas, .circunferencias, .plicometria]
        if anthropometryProfile.isISAK {
            steps.append(.diametros)
        }
        if anthropometryProfile.isFullProfile {
            steps.append(.longitudes)
        }
        steps.append(contentsOf: [.fotos, .notas, .revision])
        return steps
    }

    // MARK: - Section completion

    var hasBodyMetrics:    Bool { bodyMetrics.weightText.asPositiveDouble != nil }
    var hasCircumferences: Bool { circumferences.canSave }
    var hasSkinfolds:      Bool { skinfolds.calculationResult != nil }
    var hasISAKSkinfolds:  Bool { skinfolds.filledISAKSiteCount > 0 }
    var hasPhotos:         Bool { !photoDrafts.isEmpty }
    var hasNotes:          Bool {
        !coachNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !athleteNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isFilled(_ step: CheckInWorkflowStep) -> Bool {
        switch step {
        case .metricas:        return hasBodyMetrics
        case .circunferencias: return hasCircumferences
        case .plicometria:     return anthropometryProfile.isISAK ? hasISAKSkinfolds : hasSkinfolds
        case .diametros:       return extended.hasBreadths
        case .longitudes:      return extended.hasLengths
        case .fotos:           return hasPhotos
        case .notas:           return hasNotes
        case .revision:        return false
        }
    }

    var isakCompletionSummary: String {
        guard anthropometryProfile.isISAK else { return "" }
        let total = anthropometryProfile.totalMeasurementCount
        var filled = 0
        if hasBodyMetrics { filled += 1 }
        if bodyMetrics.sittingHeightText.asPositiveDouble != nil { filled += 1 }
        if bodyMetrics.armSpanText.asPositiveDouble != nil { filled += 1 }
        filled += skinfolds.filledISAKSiteCount
        if circumferences.armFlexedTensedText.asPositiveDouble != nil { filled += 1 }
        if circumferences.waistText.asPositiveDouble != nil { filled += 1 }
        if circumferences.hipsText.asPositiveDouble != nil { filled += 1 }
        if circumferences.rightThighText.asPositiveDouble != nil { filled += 1 }
        if circumferences.rightCalfText.asPositiveDouble != nil { filled += 1 }
        if circumferences.rightArmText.asPositiveDouble != nil { filled += 1 }
        filled += extended.filledLevel1BreadthCount
        if anthropometryProfile.isFullProfile {
            filled += extended.filledLevel2BreadthCount
            filled += extended.filledLengthCount
        }
        return "\(filled) / \(total) medidas"
    }

    // MARK: - Navigation

    var isFirstStep: Bool { currentStep == activeSteps.first }
    var isRevision:  Bool { currentStep == .revision }

    func goNext() {
        guard let i = activeSteps.firstIndex(of: currentStep), i + 1 < activeSteps.count else { return }
        currentStep = activeSteps[i + 1]
    }

    func goPrevious() {
        guard let i = activeSteps.firstIndex(of: currentStep), i > 0 else { return }
        currentStep = activeSteps[i - 1]
    }

    func profileDidChange() {
        if !activeSteps.contains(currentStep) {
            currentStep = .metricas
        }
    }

    // MARK: - Photo drafts

    /// Validates and appends a new photo draft.
    /// Rejects the photo and sets `photoAddError` if either limit is exceeded.
    /// Returns true when the draft was accepted.
    @discardableResult
    func addPhoto(data: Data, poseType: PoseType, capturedAt: Date, notes: String?) -> Bool {
        guard photoDrafts.count < Self.maxPhotosPerCheckIn else {
            photoAddError = "Puedes agregar hasta 20 fotos por check-in."
            return false
        }
        guard data.count <= Self.maxPhotoDraftBytes else {
            photoAddError = "Esta foto es demasiado grande. El tamaño máximo es 10 MB."
            return false
        }
        photoDrafts.append(PhotoDraft(data: data, poseType: poseType, capturedAt: capturedAt, notes: notes))
        return true
    }

    func removePhoto(id: UUID) {
        photoDrafts.removeAll { $0.id == id }
    }

    /// Clears all in-memory photo drafts and resets error state.
    ///
    /// No filesystem cleanup is needed here: photos are written to disk only
    /// during save() Phase B, which already compensates via rollback journal
    /// on any failure. Cancel before save() = zero filesystem artifacts.
    func cancel() {
        photoDrafts.removeAll()
        photoAddError = nil
        saveError     = nil
    }

    // MARK: - Save (compensating transaction)

    func save(context: ModelContext) {
        guard !isSaving else { return }
        isSaving  = true
        saveError = nil

        // Sync weight for Parrillo live calculation
        skinfolds.bodyWeightKg = bodyMetrics.weightText.asPositiveDouble

        // Rollback journal — relative filesystem paths written during this attempt only.
        // Only paths from THIS save attempt appear here; preexisting photos are never touched.
        var photoRollbackPaths: [String] = []

        // Prepared photo records — created in memory during Phase B,
        // inserted into context in Phase C.
        var preparedPhotos: [(photo: ProgressPhoto, relativePath: String)] = []

        // Pre-allocate CheckIn to obtain its UUID for filesystem paths in Phase B.
        // Not inserted into context until Phase C.
        let checkIn = CheckIn(date: date)
        checkIn.anthropometryProfileID = anthropometryProfile.rawValue

        // Tracks which phase failed to provide the most relevant user message.
        var photoPhaseCompleted = false

        do {
            // ── PHASE B: FILESYSTEM WRITES ──────────────────────────────────
            // Write photo files before any SwiftData inserts.
            // Each path is added to the rollback journal immediately so that
            // a failure in any subsequent phase can delete exactly these files.
            //
            // filesystem + SwiftData are not ACID-distributed; the rollback
            // journal is the compensation mechanism for filesystem resources.
            if !photoDrafts.isEmpty {
                let photoRepo = ProgressPhotoRepository.make(context: context)
                for (idx, draft) in photoDrafts.enumerated() {
                    let pair = try photoRepo.prepareNewPhoto(
                        data:       draft.data,
                        poseType:   draft.poseType,
                        sortOrder:  idx,
                        capturedAt: draft.capturedAt,
                        notes:      draft.notes,
                        athleteID:  athlete.id,
                        checkInID:  checkIn.id
                    )
                    photoRollbackPaths.append(pair.relativePath)
                    preparedPhotos.append(pair)
                }
            }
            photoPhaseCompleted = true

            // ── PHASE C: SWIFTDATA INSERTS (no save yet) ────────────────────
            // All objects are inserted but NOT saved. context.save() is deferred
            // so context.rollback() in compensation can undo all insertions if
            // Phase D (the single commit) fails.
            let ciRepo = CheckInRepository(context: context)
            ciRepo.insertNew(checkIn, into: athlete)

            let shouldInsertBodyMetrics = hasBodyMetrics
                || bodyMetrics.sittingHeightText.asPositiveDouble != nil
                || bodyMetrics.armSpanText.asPositiveDouble != nil
            if shouldInsertBodyMetrics {
                bodyMetrics.insertRecord(
                    for: checkIn,
                    using: BodyMetricsRepository(context: context)
                )
            }

            if hasCircumferences {
                circumferences.insertRecord(
                    for: checkIn,
                    using: CircumferenceMeasurementsRepository(context: context)
                )
            }

            let shouldInsertSkinfolds = anthropometryProfile.isISAK ? hasISAKSkinfolds : hasSkinfolds
            if shouldInsertSkinfolds {
                skinfolds.insertRecord(
                    for: checkIn,
                    using: SkinfoldMeasurementsRepository(context: context),
                    allowWithoutFormula: anthropometryProfile.isISAK
                )
            }

            if anthropometryProfile.isISAK && extended.hasBreadths {
                extended.insertBreadths(for: checkIn, using: ISAKBreadthsRepository(context: context))
            }

            if anthropometryProfile.isFullProfile && extended.hasLengths {
                extended.insertLengths(for: checkIn, using: ISAKLengthsRepository(context: context))
            }

            // Link prepared photo records to CheckIn and insert into context
            for pair in preparedPhotos {
                pair.photo.checkIn = checkIn
                context.insert(pair.photo)
            }

            if hasNotes {
                ciRepo.insertNotes(
                    coachText:   coachNoteText,
                    athleteText: athleteNoteText,
                    for:         checkIn
                )
            }

            // ── PHASE D: SINGLE COMMIT ───────────────────────────────────────
            // The only context.save() in the entire workflow.
            // All filesystem writes are complete. This finalizes SwiftData state.
            try context.save()

            // ── SUCCESS ──────────────────────────────────────────────────────
            // savedCheckIn is assigned ONLY after a complete, successful commit.
            // The view observes this property to dismiss the workflow.
            savedCheckIn = checkIn

        } catch {
            // ── COMPENSATION ─────────────────────────────────────────────────
            // Always attempt both SwiftData and filesystem compensation.
            // Failure in one compensation layer does not suppress the other.

            // 1. Discard all pending SwiftData insertions.
            //    Safe because context.save() has not been called successfully.
            context.rollback()

            // 2. Delete photo files written during this attempt.
            //    Only paths in the journal are deleted; preexisting photos untouched.
            //    Orphaned files from exceptional cleanup failures are eligible
            //    for Phase 21F orphan cleanup.
            if !photoRollbackPaths.isEmpty {
                let cleanup = PhotoStorageService()
                for path in photoRollbackPaths {
                    do {
                        try cleanup.delete(relativePath: path)
                    } catch {
                        AppLogger.persistence.error("CheckIn save: photo compensation failed for a file")
                    }
                }
            }

            saveError = photoPhaseCompleted
                ? "No se pudo guardar el check in. Verifica el espacio disponible e inténtalo de nuevo."
                : "No se pudieron guardar las fotos del check in. Verifica el espacio disponible e inténtalo de nuevo."
            AppLogger.persistence.error("CheckIn save failed — compensation applied")
            savedCheckIn = nil
        }

        isSaving = false
    }

    // MARK: - Helpers

    private static func ageInYears(from birthDate: Date) -> Double {
        let comps = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
        return Double(comps.year ?? 25)
    }
}
