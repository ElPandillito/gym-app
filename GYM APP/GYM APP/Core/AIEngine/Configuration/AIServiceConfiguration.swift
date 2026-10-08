//
//  AIServiceConfiguration.swift
//  GYM APP
//
//  Factory for AI service implementations.
//  Call sites depend on ImageGenerationServiceProtocol, never on concrete types.
//

import Foundation

/// Returns the appropriate ImageGenerationServiceProtocol implementation
/// based on available configuration at runtime.
///
/// Selection priority:
///   1. AppConfiguration.imageGenerationProxyURL is set
///      → BackendImageGenerationService  (production — key lives server-side)
///   2. Secrets.openAIAPIKey is non-nil
///      → RealImageGenerationService     (local dev only — never commit a real key)
///   3. Neither
///      → ImageGenerationStub            (safe no-op fallback)
///
/// For production builds always set AppConfiguration.imageGenerationProxyURL.
/// NEVER ship a real Secrets.openAIAPIKey in an App Store binary.
enum AIServiceConfiguration {

    static func makeImageGenerator() -> any ImageGenerationServiceProtocol {
        if let proxyURL = AppConfiguration.imageGenerationProxyURL {
            return BackendImageGenerationService(proxyURL: proxyURL)
        }
        if let key = Secrets.openAIAPIKey, !key.isEmpty {
            return RealImageGenerationService(apiKey: key)
        }
        // Image generation is suspended (Phase 47D). The feature will be
        // re-enabled when AppConfiguration.imageGenerationProxyURL is set.
        return ImageGenerationStub(behavior: .failure(.unavailable))
    }
}
