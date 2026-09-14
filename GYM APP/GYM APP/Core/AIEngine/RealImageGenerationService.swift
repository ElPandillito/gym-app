//
//  RealImageGenerationService.swift
//  GYM APP
//
//  Implements ImageGenerationServiceProtocol using OpenAIImageProvider.
//  Translates provider-level errors into AIServiceError before they reach the ViewModel.
//

import Foundation

struct RealImageGenerationService: ImageGenerationServiceProtocol, Sendable {

    private let provider: OpenAIImageProvider

    init(apiKey: String, session: URLSession = .shared) {
        self.provider = OpenAIImageProvider(apiKey: apiKey, session: session)
    }

    // MARK: - ImageGenerationServiceProtocol

    func generate(prompt: String) async throws -> GeneratedFoodImageData {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidInput("El prompt no puede estar vacío.")
        }

        do {
            let (imageData, usedPrompt) = try await provider.generate(prompt: prompt)
            return GeneratedFoodImageData(
                imageData:   imageData,
                mimeType:    "image/png",
                promptUsed:  usedPrompt,
                generatedAt: Date()
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let providerError as OpenAIProviderError {
            throw providerError.asAIServiceError()
        } catch {
            throw AIServiceError.serviceFailure
        }
    }
}
