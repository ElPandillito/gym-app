//
//  BackendImageGenerationServiceTests.swift
//  GYM APPTests
//
//  Tests BackendImageGenerationService using MockURLProtocol.
//  No real network calls — no API credits consumed.
//  Suite is .serialized because MockURLProtocol.requestHandler is a static var.
//

import Testing
import Foundation
@testable import GYM_APP

// MARK: - Helpers (private to this file)

private let proxyBase = URL(string: "https://test.proxy.example.com")!

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeBackendService(session: URLSession) -> BackendImageGenerationService {
    BackendImageGenerationService(proxyURL: proxyBase, session: session)
}

private func proxyHttpResponse(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: proxyBase, statusCode: status, httpVersion: nil, headerFields: nil)!
}

private func successBody(
    imageBytes: Data = Data("fake-image".utf8),
    promptUsed: String = "A bowl of rice"
) -> Data {
    let b64 = imageBytes.base64EncodedString()
    let json = "{\"imageData\": \"\(b64)\", \"mimeType\": \"image/png\", \"promptUsed\": \"\(promptUsed)\"}"
    return Data(json.utf8)
}

private func proxyErrorBody(code: String, message: String) -> Data {
    Data("{\"error\": {\"code\": \"\(code)\", \"message\": \"\(message)\"}}".utf8)
}

// MARK: - Suite

@Suite("BackendImageGenerationService", .serialized)
struct BackendImageGenerationServiceTests {

    private let session = makeMockSession()

    // MARK: - Empty / whitespace prompt

    @Test("Empty prompt throws AIServiceError.invalidInput without network call")
    func emptyPrompt_throwsInvalidInput() async {
        MockURLProtocol.requestHandler = { _ in
            Issue.record("Network call should not occur for empty prompt")
            return (proxyHttpResponse(status: 200), Data())
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "")
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
        MockURLProtocol.requestHandler = { _ in
            Issue.record("Network call should not occur for whitespace prompt")
            return (proxyHttpResponse(status: 200), Data())
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "   \t\n  ")
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

    @Test("HTTP 200 with valid base64 returns non-empty imageData")
    func success_returnsImageData() async throws {
        let fakeBytes = Data("backend-image-bytes".utf8)
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 200), successBody(imageBytes: fakeBytes))
        }
        defer { MockURLProtocol.requestHandler = nil }

        let result = try await makeBackendService(session: session).generate(prompt: "A bowl of rice")

        #expect(!result.imageData.isEmpty)
        #expect(result.imageData == fakeBytes)
        #expect(result.mimeType == "image/png")
        #expect(!result.promptUsed.isEmpty)
    }

    @Test("HTTP 200 uses promptUsed from proxy response")
    func success_usesPromptUsedFromProxy() async throws {
        let expected = "Proxy-revised prompt for a colorful salad"
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 200), successBody(promptUsed: expected))
        }
        defer { MockURLProtocol.requestHandler = nil }

        let result = try await makeBackendService(session: session).generate(prompt: "A salad")

        #expect(result.promptUsed == expected)
    }

    // MARK: - HTTP error paths

    @Test("HTTP 401 throws AIServiceError.unavailable")
    func http401_throwsUnavailable() async {
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 401), Data())
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A salad")
            Issue.record("Expected AIServiceError.unavailable")
        } catch let e as AIServiceError {
            #expect(e == .unavailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 403 throws AIServiceError.unavailable")
    func http403_throwsUnavailable() async {
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 403), Data())
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A salad")
            Issue.record("Expected AIServiceError.unavailable")
        } catch let e as AIServiceError {
            #expect(e == .unavailable)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 400 throws AIServiceError.invalidInput with proxy message")
    func http400_throwsInvalidInput() async {
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 400), proxyErrorBody(code: "invalid_prompt", message: "Prompt cannot be empty"))
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A salad")
            Issue.record("Expected AIServiceError.invalidInput")
        } catch let e as AIServiceError {
            if case .invalidInput(let msg) = e {
                #expect(!msg.isEmpty)
            } else {
                Issue.record("Expected .invalidInput, got \(e)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 500 throws AIServiceError.serviceFailure")
    func http500_throwsServiceFailure() async {
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 500), Data())
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A salad")
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
        MockURLProtocol.requestHandler = { _ in
            (proxyHttpResponse(status: 200), Data("not json at all".utf8))
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A taco")
            Issue.record("Expected AIServiceError.serviceFailure")
        } catch let e as AIServiceError {
            #expect(e == .serviceFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("HTTP 200 with invalid base64 in imageData throws AIServiceError.serviceFailure")
    func invalidBase64_throwsServiceFailure() async {
        MockURLProtocol.requestHandler = { _ in
            let json = "{\"imageData\": \"!!!not-base64!!!\", \"mimeType\": \"image/png\", \"promptUsed\": \"test\"}"
            return (proxyHttpResponse(status: 200), Data(json.utf8))
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A taco")
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
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { MockURLProtocol.requestHandler = nil }

        do {
            _ = try await makeBackendService(session: session).generate(prompt: "A taco")
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
        MockURLProtocol.requestHandler = { _ in
            try await Task.sleep(nanoseconds: 10_000_000_000)
            return (proxyHttpResponse(status: 200), successBody())
        }
        defer { MockURLProtocol.requestHandler = nil }

        let service = makeBackendService(session: session)
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
            #expect(e == .serviceFailure)
        } catch {
            // Any error on cancellation is acceptable
        }
    }
}
