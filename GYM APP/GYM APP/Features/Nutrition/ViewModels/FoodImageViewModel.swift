//
//  FoodImageViewModel.swift
//  GYM APP
//

import Foundation
import SwiftData

@Observable
@MainActor
final class FoodImageViewModel {

    // MARK: - State

    enum GenerationState {
        case idle
        case generating
        case failed(String)
    }

    private(set) var generationState: GenerationState = .idle

    var isGenerating: Bool {
        if case .generating = generationState { return true }
        return false
    }

    var errorMessage: String? {
        if case .failed(let msg) = generationState { return msg }
        return nil
    }

    // MARK: - Private

    private let food: Food
    private let repository: FoodRepository
    private let generator: any ImageGenerationServiceProtocol
    private let promptBuilder = FoodImagePromptBuilder()

    // MARK: - Init

    init(
        food: Food,
        context: ModelContext,
        generator: any ImageGenerationServiceProtocol = ImageGenerationStub(),
        imageStorage: FoodImageStorageServiceProtocol = FoodImageStorageService()
    ) {
        self.food       = food
        self.repository = FoodRepository(context: context, imageStorage: imageStorage)
        self.generator  = generator
    }

    // MARK: - Actions

    func generateAIImage() async {
        guard !isGenerating else { return }
        generationState = .generating
        do {
            let prompt = promptBuilder.makePrompt(for: food.snapshot())
            let result = try await generator.generate(prompt: prompt)
            try repository.setAIGeneratedImage(data: result.imageData, prompt: result.promptUsed, for: food)
            generationState = .idle
        } catch {
            generationState = .failed(userFacingMessage(for: error))
        }
    }

    func clearError() {
        if case .failed = generationState { generationState = .idle }
    }

    // MARK: - Private helpers

    private func userFacingMessage(for error: Error) -> String {
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .invalidInput:     return "El alimento no tiene suficiente información para generar una imagen."
            case .unavailable:      return "El servicio de generación no está disponible."
            case .serviceFailure:   return "Error al generar la imagen. Intenta de nuevo."
            case .insufficientData: return "Información insuficiente para generar una imagen."
            }
        }
        return "Error inesperado. Intenta de nuevo."
    }
}
