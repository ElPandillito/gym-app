//
//  FoodImageViewModelTests.swift
//  GYM APPTests
//
//  Integration tests for FoodImageViewModel using an in-memory SwiftData store.
//  File I/O is mocked — MockFoodImageStorage avoids disk writes in tests.
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

// MARK: - Mock storage — no real file I/O

private struct MockFoodImageStorage: FoodImageStorageServiceProtocol {
    func saveOriginal(data: Data, foodID: UUID) throws -> String { "mock/\(foodID)/image.jpg" }
    func saveThumbnail(data: Data, foodID: UUID) throws -> String { "mock/\(foodID)/thumb.jpg" }
    func generateAndSaveThumbnail(from originalRelativePath: String, foodID: UUID) throws -> String { "mock/\(foodID)/thumb.jpg" }
    func absoluteURL(for relativePath: String) -> URL { URL(fileURLWithPath: "/mock/\(relativePath)") }
    func loadData(for relativePath: String) throws -> Data { Data() }
    func delete(relativePath: String) throws {}
    func deleteFoodDirectory(foodID: UUID) throws {}
}

// MARK: - Suite

@Suite("FoodImageViewModel")
struct FoodImageViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @MainActor
    private func makeFood(in context: ModelContext) throws -> Food {
        let food = Food(name: "Pollo a la plancha", kind: .ingredient, category: .proteinas, source: .coach)
        food.calories = 165
        food.protein  = 31
        context.insert(food)
        try context.save()
        return food
    }

    @MainActor
    private func makeVM(
        food: Food,
        context: ModelContext,
        generator: any ImageGenerationServiceProtocol = ImageGenerationStub()
    ) -> FoodImageViewModel {
        FoodImageViewModel(food: food, context: context, generator: generator, imageStorage: MockFoodImageStorage())
    }

    // MARK: - Initial state

    @Test("Initial generationState is idle")
    @MainActor
    func initialState_isIdle() throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)
        if case .idle = vm.generationState { } else {
            Issue.record("Expected .idle initial state, got \(vm.generationState)")
        }
        #expect(!vm.isGenerating)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Success path

    @Test("generateAIImage success sets state back to idle")
    @MainActor
    func generateAIImage_success_stateIsIdle() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        await vm.generateAIImage()

        if case .idle = vm.generationState { } else {
            Issue.record("Expected .idle after successful generation")
        }
        #expect(!vm.isGenerating)
        #expect(vm.errorMessage == nil)
    }

    @Test("generateAIImage success links FoodImage to the food")
    @MainActor
    func generateAIImage_success_createsFoodImage() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        await vm.generateAIImage()

        #expect(food.image != nil)
    }

    @Test("generateAIImage success marks origin as aiGenerated and state as ready")
    @MainActor
    func generateAIImage_success_setsCorrectMetadata() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        await vm.generateAIImage()

        #expect(food.image?.imageOrigin == .aiGenerated)
        #expect(food.image?.aiGenerationState == .ready)
    }

    @Test("generateAIImage success persists FoodImage to the store")
    @MainActor
    func generateAIImage_success_persistsToStore() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        await vm.generateAIImage()

        let images = try container.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.count == 1)
        #expect(images.first?.imageOrigin == .aiGenerated)
    }

    // MARK: - Failure path

    @Test("generateAIImage failure sets state to failed with non-empty message")
    @MainActor
    func generateAIImage_failure_setsFailedState() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext, generator: ImageGenerationStub(behavior: .failure(.serviceFailure)))

        await vm.generateAIImage()

        if case .failed(let msg) = vm.generationState {
            #expect(!msg.isEmpty)
        } else {
            Issue.record("Expected .failed state, got \(vm.generationState)")
        }
    }

    @Test("generateAIImage failure does not create a FoodImage")
    @MainActor
    func generateAIImage_failure_noFoodImageCreated() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext, generator: ImageGenerationStub(behavior: .failure(.serviceFailure)))

        await vm.generateAIImage()

        #expect(food.image == nil)
    }

    // MARK: - Error clearing

    @Test("clearError resets state from failed to idle")
    @MainActor
    func clearError_resetsToIdle() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext, generator: ImageGenerationStub(behavior: .failure(.serviceFailure)))

        await vm.generateAIImage()
        vm.clearError()

        if case .idle = vm.generationState { } else {
            Issue.record("Expected .idle after clearError")
        }
        #expect(vm.errorMessage == nil)
    }

    @Test("clearError is a no-op when state is already idle")
    @MainActor
    func clearError_noopWhenIdle() throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        vm.clearError()  // must not crash

        if case .idle = vm.generationState { } else {
            Issue.record("Expected .idle after no-op clearError")
        }
    }

    // MARK: - Duplicate prevention

    @Test("Calling generateAIImage twice replaces the image without duplicates")
    @MainActor
    func generateAIImage_calledTwice_noDuplicates() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        await vm.generateAIImage()
        await vm.generateAIImage()

        let images = try container.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.count == 1, "Should have exactly one FoodImage after two generate calls")
    }

    // MARK: - promptUsed persistence (Phase 39 field)

    @Test("generateAIImage success persists promptUsed on the FoodImage")
    @MainActor
    func generateAIImage_success_persistsPromptUsed() async throws {
        let container = try makeContainer()
        let food = try makeFood(in: container.mainContext)
        let vm = makeVM(food: food, context: container.mainContext)

        await vm.generateAIImage()

        #expect(food.image?.promptUsed != nil)
        #expect(food.image?.promptUsed?.isEmpty == false)
    }
}
