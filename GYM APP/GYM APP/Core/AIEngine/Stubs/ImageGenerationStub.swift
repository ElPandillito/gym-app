//
//  ImageGenerationStub.swift
//  GYM APP
//
//  Deterministic stub for ImageGenerationServiceProtocol.
//  No network calls. No credentials required.
//  Suitable for development, SwiftUI previews, and unit tests.
//
//  Supports three configurable behaviors:
//    .success  — returns a fixed, non-empty Data payload
//    .failure  — throws the configured AIServiceError
//  and an optional simulated delay (safe for tests at small values).
//

import Foundation

struct ImageGenerationStub: ImageGenerationServiceProtocol {

    // MARK: - Configuration

    enum Behavior: Sendable {
        /// Return a fixed deterministic placeholder image.
        case success
        /// Throw the given error after the optional delay.
        case failure(AIServiceError)
    }

    let behavior: Behavior
    /// Simulated async delay in nanoseconds. Use 0 for fast tests.
    let delayNanoseconds: UInt64
    let clock: @Sendable () -> Date

    init(
        behavior: Behavior = .success,
        delayNanoseconds: UInt64 = 0,
        clock: @Sendable @escaping () -> Date = { Date() }
    ) {
        self.behavior         = behavior
        self.delayNanoseconds = delayNanoseconds
        self.clock            = clock
    }

    // MARK: - ImageGenerationServiceProtocol

    func generate(prompt: String) async throws -> GeneratedFoodImageData {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidInput("El prompt no puede estar vacío.")
        }

        if delayNanoseconds > 0 {
            // Propagates CancellationError when the enclosing Task is cancelled.
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if case .failure(let error) = behavior {
            throw error
        }

        return GeneratedFoodImageData(
            imageData:   Self.placeholderData,
            mimeType:    "image/png",
            promptUsed:  prompt,
            generatedAt: clock()
        )
    }

    // MARK: - Fixed placeholder

    /// Stable, non-empty Data used as the stub image payload.
    /// Not a valid image format — only suitable for testing data flow.
    private static let placeholderData = Data("GYM_APP_IMAGE_GENERATION_STUB".utf8)
}
