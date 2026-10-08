//
//  BackendImageGenerationService.swift
//  GYM APP
//
//  Implements ImageGenerationServiceProtocol by calling the gym-app backend proxy.
//  The proxy holds the OpenAI API key server-side — it never exists in the client bundle.
//
//  Proxy contract:
//    POST {proxyURL}/v1/image-generation
//    Body:    { "prompt": String, "requestID": String }
//    200 OK:  { "imageData": String (base64), "mimeType": String, "promptUsed": String }
//    400:     { "error": { "code": String, "message": String } }
//    401/403: proxy-level auth failure
//    5xx:     service failure
//

import Foundation

// MARK: - DTOs (private to this file)

private struct BackendImageRequest: Encodable {
    let prompt: String
    let requestID: String
}

private struct BackendImageResponse: Decodable {
    let imageData: String
    let mimeType: String
    let promptUsed: String
}

private struct BackendErrorBody: Decodable {
    struct BackendError: Decodable {
        let code: String
        let message: String
    }
    let error: BackendError
}

// MARK: - Service

struct BackendImageGenerationService: ImageGenerationServiceProtocol, Sendable {

    private let proxyURL: URL
    private let session: URLSession

    init(proxyURL: URL, session: URLSession = .shared) {
        self.proxyURL = proxyURL
        self.session  = session
    }

    // MARK: - ImageGenerationServiceProtocol

    func generate(prompt: String) async throws -> GeneratedFoodImageData {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidInput("El prompt no puede estar vacío.")
        }

        let endpoint = proxyURL.appendingPathComponent("v1/image-generation")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfiguration.imageGenerationProxyToken, forHTTPHeaderField: "X-App-Token")
        request.httpBody = try JSONEncoder().encode(
            BackendImageRequest(prompt: prompt, requestID: UUID().uuidString)
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .cancelled { throw CancellationError() }
            throw AIServiceError.serviceFailure
        }

        try Task.checkCancellation()

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.serviceFailure
        }

        switch http.statusCode {
        case 200:
            break
        case 400:
            let msg = proxyErrorMessage(from: data) ?? "Solicitud inválida."
            throw AIServiceError.invalidInput(msg)
        case 401, 403:
            throw AIServiceError.unavailable
        default:
            throw AIServiceError.serviceFailure
        }

        let decoded: BackendImageResponse
        do {
            decoded = try JSONDecoder().decode(BackendImageResponse.self, from: data)
        } catch {
            throw AIServiceError.serviceFailure
        }

        guard let imageData = Data(base64Encoded: decoded.imageData) else {
            throw AIServiceError.serviceFailure
        }

        return GeneratedFoodImageData(
            imageData:   imageData,
            mimeType:    decoded.mimeType,
            promptUsed:  decoded.promptUsed,
            generatedAt: Date()
        )
    }

    // MARK: - Private helpers

    private func proxyErrorMessage(from data: Data) -> String? {
        try? JSONDecoder().decode(BackendErrorBody.self, from: data).error.message
    }
}
