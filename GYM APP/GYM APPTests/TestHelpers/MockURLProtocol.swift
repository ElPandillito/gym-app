//
//  MockURLProtocol.swift
//  GYM APPTests
//
//  Shared URLProtocol mock for network-free tests.
//  Used by RealImageGenerationServiceTests and BackendImageGenerationServiceTests.
//  Any suite that uses MockURLProtocol MUST be .serialized — requestHandler is a static var.
//

import Foundation

/// Intercepta toda petición de red de la URLSession bajo prueba.
/// `requestHandler` es async para permitir Task.sleep() en tests de cancellation.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    static var requestHandler: (@Sendable (URLRequest) async throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
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


