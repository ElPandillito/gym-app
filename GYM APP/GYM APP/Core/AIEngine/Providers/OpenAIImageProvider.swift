//
//  OpenAIImageProvider.swift
//  GYM APP
//
//  Low-level HTTP client for the OpenAI Images API (DALL·E 3).
//  Handles request construction, response decoding, and HTTP error mapping.
//  Does not contain business logic, SwiftData, or UI code.
//
//  API reference: https://platform.openai.com/docs/api-reference/images/create
//  Model used: dall-e-3 (1024×1024, standard quality, b64_json output)
//

import Foundation

// MARK: - Request / response types (private to this file)

private struct OpenAIImageRequest: Encodable {
    let model = "dall-e-3"
    let prompt: String
    let n = 1
    let size = "1024x1024"
    let quality = "standard"
    let responseFormat = "b64_json"

    enum CodingKeys: String, CodingKey {
        case model, prompt, n, size, quality
        case responseFormat = "response_format"
    }
}

private struct OpenAIImageResponse: Decodable {
    struct Item: Decodable {
        let b64Json: String
        let revisedPrompt: String?
        enum CodingKeys: String, CodingKey {
            case b64Json = "b64_json"
            case revisedPrompt = "revised_prompt"
        }
    }
    let created: Int
    let data: [Item]
}

private struct OpenAIErrorBody: Decodable {
    struct APIError: Decodable {
        let message: String
        let type: String?
        let code: String?
    }
    let error: APIError
}

// MARK: - Provider errors

/// Detailed errors from the OpenAI HTTP layer.
/// Mapped to AIServiceError by RealImageGenerationService before reaching the ViewModel.
enum OpenAIProviderError: Error, Sendable {
    case missingAPIKey
    case unauthorized(String)       // 401
    case rateLimited(String)        // 429
    case badRequest(String)         // 400
    case serverError(Int, String)   // 5xx
    case emptyResponseData          // 200 but data[] is empty
    case invalidBase64              // b64_json can't be decoded
    case networkError(URLError)     // connectivity failure
    case unexpectedStatus(Int, String)
    case decodingError(String)
}

extension OpenAIProviderError {
    /// Converts provider-level detail into the protocol-level AIServiceError.
    func asAIServiceError() -> AIServiceError {
        switch self {
        case .missingAPIKey, .unauthorized:
            return .unavailable
        case .rateLimited:
            return .serviceFailure
        case .badRequest(let msg):
            return .invalidInput(msg)
        case .serverError, .unexpectedStatus,
             .emptyResponseData, .invalidBase64,
             .decodingError:
            return .serviceFailure
        case .networkError:
            return .serviceFailure
        }
    }
}

// MARK: - Provider

struct OpenAIImageProvider: Sendable {

    private static let endpoint = URL(string: "https://api.openai.com/v1/images/generations")!

    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey   = apiKey
        self.session  = session
    }

    /// Sends a generation request and returns raw image bytes plus the (possibly revised) prompt.
    /// Throws `OpenAIProviderError` for all failure modes.
    /// Propagates `CancellationError` when the enclosing Task is cancelled.
    func generate(prompt: String) async throws -> (imageData: Data, promptUsed: String) {
        let body    = OpenAIImageRequest(prompt: prompt)
        let encoded = try JSONEncoder().encode(body)

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.httpBody = encoded

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .cancelled { throw CancellationError() }
            throw OpenAIProviderError.networkError(urlError)
        }

        try Task.checkCancellation()

        guard let http = response as? HTTPURLResponse else {
            throw OpenAIProviderError.unexpectedStatus(0, "Non-HTTP response")
        }

        switch http.statusCode {
        case 200:
            break
        case 401:
            let msg = errorMessage(from: data) ?? "Clave de API inválida."
            throw OpenAIProviderError.unauthorized(msg)
        case 429:
            let msg = errorMessage(from: data) ?? "Límite de solicitudes alcanzado."
            throw OpenAIProviderError.rateLimited(msg)
        case 400:
            let msg = errorMessage(from: data) ?? "Solicitud inválida."
            throw OpenAIProviderError.badRequest(msg)
        case 500...599:
            let msg = errorMessage(from: data) ?? "Error del servidor OpenAI."
            throw OpenAIProviderError.serverError(http.statusCode, msg)
        default:
            let msg = errorMessage(from: data) ?? "HTTP \(http.statusCode)."
            throw OpenAIProviderError.unexpectedStatus(http.statusCode, msg)
        }

        let decoded: OpenAIImageResponse
        do {
            decoded = try JSONDecoder().decode(OpenAIImageResponse.self, from: data)
        } catch {
            throw OpenAIProviderError.decodingError(error.localizedDescription)
        }

        guard let item = decoded.data.first else {
            throw OpenAIProviderError.emptyResponseData
        }
        guard let imageData = Data(base64Encoded: item.b64Json) else {
            throw OpenAIProviderError.invalidBase64
        }

        // dall-e-3 may revise the prompt for safety/quality — store the actual prompt used
        let usedPrompt = item.revisedPrompt ?? prompt
        return (imageData: imageData, promptUsed: usedPrompt)
    }

    // MARK: - Private helpers

    private func errorMessage(from data: Data) -> String? {
        try? JSONDecoder().decode(OpenAIErrorBody.self, from: data).error.message
    }
}
