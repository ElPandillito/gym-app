//
//  RealImageGenerationServiceTests.swift
//  GYM APPTests
//
//  Tests RealImageGenerationService and OpenAIImageProvider using OpenAIMockURLProtocol.
//  No real network calls — no API credits consumed.
//  Suite is .serialized because OpenAIMockURLProtocol.requestHandler is a static var.
//

import Testing
import Foundation
@testable import GYM_APP

// MARK: - Local mock (dedicated class — prevents handler collision with BackendImageGenerationServiceTests)

private final class OpenAIMockURLProtocol: URLProtocol, @unchecked Sendable {

    static var requestHandler: (@Sendable (URLRequest) async throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = OpenAIMockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let client  = client
        let request = request
        Task {
            do {
                let (response, data) = try await handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private let testEndpoint = URL(string: "https://api.openai.com/v1/images/generations")!

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [OpenAIMockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeService(session: URLSession) -> RealImageGenerationService {
    RealImageGenerationService(apiKey: "test-key-123", session: session)
}

private func httpResponse(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: testEndpoint, statusCode: status, httpVersion: nil, headerFields: nil)!
}

private func successBody(imageBytes: Data = Data("fake-image".utf8), revisedPrompt: String? = nil) -> Data {
    let b64 = imageBytes.base64EncodedString()
    let revisedField = revisedPrompt.map { ", \"revised_prompt\": \"\($0)\"" } ?? ""
    let json = #"{"created": 1700000000, "data": [{"b64_json": ""# + b64 + #"""# + revisedField + #"}]}"#
    return Data(json.utf8)
}

private func errorBody(message: String) -> Data {
    Data("""
    {"error": {"message": "\(message)", "type": "invalid_request_error", "code": null}}
    """.utf8)
}

// MARK: - Suite

@Suite("RealImageGenerationService", .serialized)
struct RealImageGenerationServiceTests {

    private let session = makeMockSession()

    // MARK: - Empty / whitespace prompt

    @Test("Empty prompt throws AIServiceError.invalidInput without network call")
    func emptyPrompt_throwsInvalidInput() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            Issue.record("Network call should not occur for empty prompt")
            return (httpResponse(status: 200), Data())
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        let service = makeService(session: session)
        do {
            _ = try await service.generate(prompt: "")
            Issue.record("Expected AIServiceError.invalidInput")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Whitespace-only prompt throws AIServiceError.invalidInput without network call")
    func whitespacePrompt_throwsInvalidInput() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            Issue.record("Network call should not occur for whitespace prompt")
            return (httpResponse(status: 200), Data())
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        let service = makeService(session: session)
        do {
            _ = try await service.generate(prompt: "   \t\n  ")
            Issue.record("Expected AIServiceError.invalidInput")
        } catch let e as AIServiceError {
            if case .invalidInput = e { } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Success path

    @Test("HTTP 200 with valid b64_json returns non-empty imageData")
    func success_returnsImageData() async throws {
        let fakeBytes = Data("fake-image-bytes".utf8)
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 200), successBody(imageBytes: fakeBytes))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        let result = try await makeService(session: session).generate(prompt: "A bowl of rice")

        #expect(!result.imageData.isEmpty)
        #expect(result.imageData == fakeBytes)
        #expect(result.mimeType == "image/png")
        #expect(!result.promptUsed.isEmpty)
    }

    @Test("HTTP 200 with revised_prompt uses provider's revised prompt")
    func success_usesRevisedPrompt() async throws {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 200), successBody(revisedPrompt: "A revised version of the prompt"))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        let result = try await makeService(session: session).generate(prompt: "A bowl of rice")

        #expect(result.promptUsed == "A revised version of the prompt")
    }

    @Test("HTTP 200 without revised_prompt falls back to original prompt")
    func success_fallsBackToOriginalPrompt() async throws {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 200), successBody())
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        let original = "A bowl of rice without revision"
        let result = try await makeService(session: session).generate(prompt: original)

        #expect(result.promptUsed == original)
    }

    // MARK: - HTTP error paths

    @Test("HTTP 401 throws AIServiceError.unavailable")
    func http401_throwsUnavailable() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 401), errorBody(message: "Invalid API key"))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A salad")
            Issue.record("Expected AIServiceError.unavailable")
        } catch let e as AIServiceError {
            #expect(e == .unavailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 429 throws AIServiceError.serviceFailure")
    func http429_throwsServiceFailure() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 429), errorBody(message: "Rate limit exceeded"))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A salad")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 500 throws AIServiceError.serviceFailure")
    func http500_throwsServiceFailure() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 500), errorBody(message: "Internal server error"))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A salad")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Malformed response

    @Test("Unparseable JSON body on HTTP 200 throws AIServiceError.serviceFailure")
    func invalidJSON_throwsServiceFailure() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 200), Data("not json at all".utf8))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A taco")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 200 with empty data array throws AIServiceError.serviceFailure")
    func emptyDataArray_throwsServiceFailure() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            (httpResponse(status: 200), Data(#"{"created":1700000000,"data":[]}"#.utf8))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A taco")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 200 with invalid base64 throws AIServiceError.serviceFailure")
    func invalidBase64_throwsServiceFailure() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            let json = #"{"created":1700000000,"data":[{"b64_json":"!!!not-base64!!!"}]}"#
            return (httpResponse(status: 200), Data(json.utf8))
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A taco")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Network error

    @Test("URLError.notConnectedToInternet throws AIServiceError.serviceFailure")
    func networkError_throwsServiceFailure() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeService(session: session).generate(prompt: "A taco")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Cancellation

    @Test("Cancelling the Task propagates as CancellationError or serviceFailure")
    func cancellation_propagates() async {
        OpenAIMockURLProtocol.requestHandler = { _ in
            // Hold the request open long enough to be cancelled
            try await Task.sleep(nanoseconds: 10_000_000_000)
            return (httpResponse(status: 200), successBody())
        }
        defer { OpenAIMockURLProtocol.requestHandler = nil }

        let service = makeService(session: session)
        let task = Task<GeneratedFoodImageData, Error> {
            try await service.generate(prompt: "A taco")
        }
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected an error on cancellation")
        } catch is CancellationError {
            // Best case: CancellationError propagated correctly
        } catch let e as AIServiceError {
            // URLSession may surface task cancellation as a URLError → serviceFailure — acceptable
            #expect(e == .serviceFailure)
        } catch {
            // Any error on cancellation is acceptable
        }
    }
}
