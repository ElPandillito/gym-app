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

    /// First-layer token sent in the X-App-Token header to the image proxy.
    ///
    /// This is NOT a strong secret — it is embedded in a distributed binary and
    /// can be extracted. Its purpose is to raise the cost of basic automation and
    /// casual abuse before the real server-side secret (APP_TOKEN stored in
    /// Cloudflare) can terminate the request.
    ///
    /// Image generation is currently SUSPENDED (imageGenerationProxyURL == nil).
    /// This placeholder is intentionally inert — it is never sent to any service
    /// while the proxy URL is nil.
    ///
    /// Before re-enabling: replace this with a generated value and set the same
    /// value as the APP_TOKEN secret via `wrangler secret put APP_TOKEN`.
    /// Do NOT commit a production value here.
    static let imageGenerationProxyToken: String = "gymapp-dev-placeholder-replace-before-deploy"
}
