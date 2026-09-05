//
//  PhotoLimitsTests.swift
//  GYM APPTests
//
//  Phase 21F regression — photo count limit, size limit, cancel safety.
//

import Testing
import Foundation
@testable import GYM_APP

@Suite("Phase 21F — Photo Limits")
struct PhotoLimitsTests {

    private func makeAthlete() -> Athlete { Athlete(name: "Test", gender: .male) }

    // MARK: - Count limit (max 20)

    @Test("accepts exactly 20 photos without error")
    @MainActor
    func acceptsTwentyPhotos() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        for _ in 0..<20 {
            let accepted = vm.addPhoto(
                data: Data(count: 1), poseType: .frontRelaxed,
                capturedAt: .distantPast, notes: nil
            )
            #expect(accepted)
        }
        #expect(vm.photoDrafts.count == 20)
        #expect(vm.photoAddError == nil)
    }

    @Test("rejects 21st photo and sets photoAddError")
    @MainActor
    func rejectsTwentyFirstPhoto() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        for _ in 0..<20 {
            _ = vm.addPhoto(data: Data(count: 1), poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        }
        let rejected = vm.addPhoto(data: Data(count: 1), poseType: .backRelaxed, capturedAt: .distantPast, notes: nil)
        #expect(!rejected)
        #expect(vm.photoDrafts.count == 20)
        #expect(vm.photoAddError != nil)
    }

    @Test("canAddPhoto is false when at limit")
    @MainActor
    func canAddPhotoFalseAtLimit() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        for _ in 0..<20 {
            _ = vm.addPhoto(data: Data(count: 1), poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        }
        #expect(!vm.canAddPhoto)
    }

    @Test("canAddPhoto is true below limit")
    @MainActor
    func canAddPhotoTrueBelowLimit() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        #expect(vm.canAddPhoto)
    }

    @Test("maxPhotosPerCheckIn constant equals 20")
    func maxPhotosConstantIs20() {
        #expect(CheckInWorkflowViewModel.maxPhotosPerCheckIn == 20)
    }

    // MARK: - Size limit (max 10 MB)

    @Test("rejects photo larger than 10 MB")
    @MainActor
    func rejectsOversizedPhoto() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        let oversize = Data(count: 10 * 1024 * 1024 + 1)
        let rejected = vm.addPhoto(data: oversize, poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        #expect(!rejected)
        #expect(vm.photoDrafts.isEmpty)
        #expect(vm.photoAddError != nil)
    }

    @Test("accepts photo at exactly 10 MB")
    @MainActor
    func acceptsPhotoAtExactLimit() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        let exact = Data(count: 10 * 1024 * 1024)
        let accepted = vm.addPhoto(data: exact, poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        #expect(accepted)
        #expect(vm.photoDrafts.count == 1)
    }

    // MARK: - Cancel safety

    @Test("cancel clears photoDrafts and resets all error state")
    @MainActor
    func cancelClearsAllState() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        _ = vm.addPhoto(data: Data(count: 1), poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        _ = vm.addPhoto(data: Data(count: 1), poseType: .backRelaxed,  capturedAt: .distantPast, notes: nil)
        vm.cancel()
        #expect(vm.photoDrafts.isEmpty)
        #expect(vm.photoAddError == nil)
        #expect(vm.saveError     == nil)
    }

    @Test("cancel after rejected oversized photo clears photoAddError")
    @MainActor
    func cancelAfterErrorClearsError() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        _ = vm.addPhoto(data: Data(count: 11 * 1024 * 1024), poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        #expect(vm.photoAddError != nil)
        vm.cancel()
        #expect(vm.photoAddError == nil)
    }

    @Test("removePhoto reduces photoDrafts count by one")
    @MainActor
    func removePhotoReducesCount() {
        let vm = CheckInWorkflowViewModel(athlete: makeAthlete())
        _ = vm.addPhoto(data: Data(count: 1), poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        _ = vm.addPhoto(data: Data(count: 1), poseType: .backRelaxed,  capturedAt: .distantPast, notes: nil)
        let idToRemove = vm.photoDrafts[0].id
        vm.removePhoto(id: idToRemove)
        #expect(vm.photoDrafts.count == 1)
        #expect(!vm.photoDrafts.contains { $0.id == idToRemove })
    }
}
