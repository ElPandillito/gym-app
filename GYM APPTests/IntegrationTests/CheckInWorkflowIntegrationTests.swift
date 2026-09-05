//
//  CheckInWorkflowIntegrationTests.swift
//  GYM APPTests
//
//  Integration tests for CheckInWorkflowViewModel.save() using an in-memory SwiftData store.
//  No filesystem operations — tests use no-photo saves to avoid real file I/O.
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

@Suite("CheckInWorkflow Integration")
struct CheckInWorkflowIntegrationTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - Happy path

    @Test("save succeeds and sets savedCheckIn for no-photo check-in")
    @MainActor
    func saveSucceedsWithNoPhotos() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Test", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let vm = CheckInWorkflowViewModel(athlete: athlete)
        vm.save(context: ctx)

        #expect(vm.savedCheckIn != nil)
        #expect(vm.saveError    == nil)
        #expect(!vm.isSaving)
    }

    @Test("save persists CheckIn to the context")
    @MainActor
    func savePersistsCheckInToContext() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Test", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let vm = CheckInWorkflowViewModel(athlete: athlete)
        vm.save(context: ctx)

        let fetched = try ctx.fetch(FetchDescriptor<CheckIn>())
        #expect(fetched.count == 1)
    }

    @Test("save links CheckIn to athlete")
    @MainActor
    func saveLinksCheckInToAthlete() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Test", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let vm = CheckInWorkflowViewModel(athlete: athlete)
        vm.save(context: ctx)

        let saved = try #require(vm.savedCheckIn)
        #expect(saved.athlete?.id == athlete.id)
    }

    @Test("save persists BodyMetrics when weight is entered")
    @MainActor
    func savePersistsBodyMetricsWhenWeightSet() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Test", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let vm = CheckInWorkflowViewModel(athlete: athlete)
        vm.bodyMetrics.weightText = "78"
        vm.save(context: ctx)

        let allMetrics = try ctx.fetch(FetchDescriptor<BodyMetrics>())
        #expect(!allMetrics.isEmpty)
    }

    // MARK: - Cancel before save

    @Test("cancel before save produces no CheckIn in context")
    @MainActor
    func cancelBeforeSaveProducesNoCheckIn() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Test", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let vm = CheckInWorkflowViewModel(athlete: athlete)
        _ = vm.addPhoto(data: Data(count: 1), poseType: .frontRelaxed, capturedAt: .distantPast, notes: nil)
        vm.cancel()

        #expect(vm.photoDrafts.isEmpty)
        #expect(vm.savedCheckIn == nil)

        let fetched = try ctx.fetch(FetchDescriptor<CheckIn>())
        #expect(fetched.isEmpty)
    }

    // MARK: - isSaving guard

    @Test("isSaving is false after synchronous save completes")
    @MainActor
    func isSavingFalseAfterCompletion() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let athlete = Athlete(name: "Test", gender: .male)
        ctx.insert(athlete)
        try ctx.save()

        let vm = CheckInWorkflowViewModel(athlete: athlete)
        vm.save(context: ctx)

        #expect(!vm.isSaving)
    }
}
