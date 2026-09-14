//
//  AppConfiguration.swift
//  GYM APP
//
//  Non-sensitive runtime configuration — version-controlled.
//  Unlike Secrets.swift (gitignored), values here are safe to commit.
//

import Foundation

/// Non-sensitive application configuration.
///
/// Selection priority in AIServiceConfiguration.makeImageGenerator():
///   1. imageGenerationProxyURL is set → BackendImageGenerationService  (production)
///   2. Secrets.openAIAPIKey is set    → RealImageGenerationService      (local dev only)
///   3. Neither                        → ImageGenerationStub              (safe fallback)
enum AppConfiguration {

    /// URL of the backend image generation proxy.
    ///
    /// Set to your deployed Cloudflare Worker URL to enable AI image generation
    /// without embedding the OpenAI key in the client bundle.
    ///
    /// Example: URL(string: "https://gym-app-images.your-subdomain.workers.dev")
    ///
    /// nil → falls through to Secrets.openAIAPIKey check (then stub).
    static let imageGenerationProxyURL: URL? = nil
}
