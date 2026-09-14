//
//  FoodImageRepositoryTests.swift
//  GYM APPTests
//
//  Tests FoodRepository image operations using an in-memory SwiftData store
//  and a mock storage service (no disk I/O).
//

import Testing
import SwiftData
import Foundation
@testable import GYM_APP

// MARK: - Mock storage

private struct MockStorage: FoodImageStorageServiceProtocol {
    func saveOriginal(data: Data, foodID: UUID) throws -> String { "Foods/\(foodID)/original/image.jpg" }
    func saveThumbnail(data: Data, foodID: UUID) throws -> String { "Foods/\(foodID)/thumbnail/image.jpg" }
    func generateAndSaveThumbnail(from originalRelativePath: String, foodID: UUID) throws -> String {
        "Foods/\(foodID)/thumbnail/image.jpg"
    }
    func absoluteURL(for relativePath: String) -> URL { URL(fileURLWithPath: "/mock/\(relativePath)") }
    func loadData(for relativePath: String) throws -> Data { Data("mock-image".utf8) }
    func delete(relativePath: String) throws {}
    func deleteFoodDirectory(foodID: UUID) throws {}
}

// MARK: - Suite

@Suite("FoodRepository — image operations", .serialized)
struct FoodImageRepositoryTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(GYMAppSchemaV1.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @MainActor
    private func makeFood(in context: ModelContext) throws -> Food {
        let food = Food(name: "Salmón al horno", kind: .ingredient, category: .proteinas, source: .coach)
        food.calories = 208; food.protein = 20
        context.insert(food)
        try context.save()
        return food
    }

    private func makeRepo(context: ModelContext) -> FoodRepository {
        FoodRepository(context: context, imageStorage: MockStorage())
    }

    // MARK: - setImage

    @Test("setImage creates FoodImage linked to food")
    @MainActor
    func setImage_createsFoodImage() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setImage(data: Data("img".utf8), for: food)

        #expect(food.image != nil)
        #expect(food.image?.originalPath.isEmpty == false)
    }

    @Test("setImage persists FoodImage to store")
    @MainActor
    func setImage_persistsToStore() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setImage(data: Data("img".utf8), for: food)

        let images = try c.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.count == 1)
    }

    @Test("setImage replaces existing image without duplicates")
    @MainActor
    func setImage_replacesExisting_noDuplicates() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setImage(data: Data("img1".utf8), for: food)
        let firstID = food.image?.id
        try repo.setImage(data: Data("img2".utf8), for: food)

        let images = try c.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.count == 1, "Exactly one FoodImage after two setImage calls")
        #expect(food.image?.id != firstID, "FoodImage should be a new record")
    }

    // MARK: - setAIGeneratedImage

    @Test("setAIGeneratedImage creates FoodImage with aiGenerated origin")
    @MainActor
    func setAIGeneratedImage_setsOrigin() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setAIGeneratedImage(data: Data("ai".utf8), prompt: "Salmón a la plancha", for: food)

        #expect(food.image?.imageOrigin == .aiGenerated)
        #expect(food.image?.aiGenerationState == .ready)
    }

    @Test("setAIGeneratedImage persists promptUsed")
    @MainActor
    func setAIGeneratedImage_persistsPromptUsed() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)
        let prompt = "Professional photo of grilled salmon on white plate"

        try repo.setAIGeneratedImage(data: Data("ai".utf8), prompt: prompt, for: food)

        #expect(food.image?.promptUsed == prompt)
    }

    @Test("setAIGeneratedImage generates a thumbnail path")
    @MainActor
    func setAIGeneratedImage_generatesThumbnail() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setAIGeneratedImage(data: Data("ai".utf8), prompt: "test", for: food)

        #expect(food.image?.thumbnailPath != nil)
    }

    @Test("setAIGeneratedImage replacing existing image does not create duplicates")
    @MainActor
    func setAIGeneratedImage_replacesExisting_noDuplicates() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setAIGeneratedImage(data: Data("ai1".utf8), prompt: "first", for: food)
        try repo.setAIGeneratedImage(data: Data("ai2".utf8), prompt: "second", for: food)

        let images = try c.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.count == 1)
        #expect(food.image?.promptUsed == "second")
    }

    // MARK: - removeImage

    @Test("removeImage deletes FoodImage from store")
    @MainActor
    func removeImage_deletesRecord() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setImage(data: Data("img".utf8), for: food)
        try repo.removeImage(from: food)

        #expect(food.image == nil)
        let images = try c.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.isEmpty)
    }

    @Test("removeImage on food without image is a no-op")
    @MainActor
    func removeImage_noImage_isNoop() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.removeImage(from: food)  // must not throw

        #expect(food.image == nil)
    }

    // MARK: - Persistence round-trip

    @Test("Image metadata persists across context refetch")
    @MainActor
    func image_persistsAfterRefetch() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let foodID = food.id
        let repo = makeRepo(context: c.mainContext)

        try repo.setAIGeneratedImage(data: Data("ai".utf8), prompt: "test prompt", for: food)

        let fetched = try c.mainContext.fetch(
            FetchDescriptor<Food>(predicate: #Predicate { $0.id == foodID })
        ).first

        #expect(fetched?.image != nil)
        #expect(fetched?.image?.imageOrigin == .aiGenerated)
        #expect(fetched?.image?.promptUsed == "test prompt")
    }

    @Test("Deleting food cascades to its FoodImage")
    @MainActor
    func deleteFood_cascadesToFoodImage() throws {
        let c = try makeContainer()
        let food = try makeFood(in: c.mainContext)
        let repo = makeRepo(context: c.mainContext)

        try repo.setImage(data: Data("img".utf8), for: food)
        try repo.forceDelete(food)

        let images = try c.mainContext.fetch(FetchDescriptor<FoodImage>())
        #expect(images.isEmpty)
    }
}
