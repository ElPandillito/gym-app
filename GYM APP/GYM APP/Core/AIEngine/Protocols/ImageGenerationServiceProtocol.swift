//
//  ImageGenerationServiceProtocol.swift
//  GYM APP
//

import Foundation

/// Contract for generating a visual food image from a text prompt.
///
/// Implementations range from deterministic stubs (ImageGenerationStub)
/// to real provider integrations (OpenAI DALL·E, Stability AI, etc.).
/// The protocol is intentionally provider-agnostic.
///
/// Security constraints:
///   - The prompt MUST NOT contain personal data (athlete name, weight, diagnostics, etc.).
///   - This service does NOT calculate macros or modify nutritional data.
///   - Storage of the returned bytes is the caller's responsibility.
///   - A generated image must never silently overwrite a user-uploaded photo.
protocol ImageGenerationServiceProtocol {
    /// Generates a food image from the supplied text prompt.
    ///
    /// - Parameter prompt: A visual description of the food. Must not contain personal data.
    /// - Returns: A `GeneratedFoodImageData` value with raw image bytes and provenance.
    /// - Throws: `AIServiceError.invalidInput` when the prompt is empty or blank.
    ///           `AIServiceError.unavailable` when the provider is not configured.
    ///           `AIServiceError.serviceFailure` for unexpected provider errors.
    func generate(prompt: String) async throws -> GeneratedFoodImageData
}

// MARK: - Result

/// The output of a successful image generation request.
/// Intentionally small — the caller decides how and where to persist the bytes.
struct GeneratedFoodImageData: Sendable {
    /// Raw image bytes (JPEG or PNG depending on the provider).
    let imageData: Data
    /// MIME type of the image (e.g. "image/jpeg" or "image/png").
    let mimeType: String
    /// The exact prompt that was sent to the provider, stored for auditability.
    let promptUsed: String
    let generatedAt: Date
}
