//
//  URLSessionProtocolTransport.swift
//  BackendService
//
//  Created by Naif Alrashed on 29/10/2024.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
@preconcurrency import Pulse

// MARK: - URLSessionProtocolTransport

struct URLSessionProtocolTransport: ClientTransport {

    // MARK: Properties

    var session: URLSessionProtocol

    // MARK: Lifecycle

    init(session: URLSessionProtocol = URLSessionProxy(configuration: .default)) {
        self.session = session
    }

    // MARK: Functions

    /// Sends the underlying HTTP request and returns the received HTTP response.
    /// - Parameters:
    ///   - request: An HTTP request.
    ///   - requestBody: An HTTP request body.
    ///   - baseURL: A server base URL.
    ///   - operationID: The identifier of the OpenAPI operation.
    /// - Returns: An HTTP response and its body.
    /// - Throws: If there was an error performing the HTTP request.
    func send(_ request: HTTPRequest,
              body: HTTPBody?,
              baseURL: URL,
              operationID _: String) async throws -> (HTTPResponse, HTTPBody?) {
        var urlRequest = try URLRequest(request, baseURL: baseURL)
        if let body {
            urlRequest.httpBody = try await Data(collecting: body, upTo: .max)
        }
        let (data, response) = try await session.data(for: urlRequest)
        let body = HTTPBody(data, length: HTTPBody.Length(from: response), iterationBehavior: .multiple)
        return try (HTTPResponse(response), body)
    }
}

extension HTTPBody.Length {
    init(from urlResponse: URLResponse) {
        if urlResponse.expectedContentLength == -1 {
            self = .unknown
        } else {
            self = .known(urlResponse.expectedContentLength)
        }
    }
}

// MARK: - URLSessionTransportError

/// Specialized error thrown by the transport.
private enum URLSessionTransportError: Error {

    /// Invalid URL composed from base URL and received request.
    case invalidRequestURL(path: String, method: HTTPRequest.Method, baseURL: URL)

    /// Returned `URLResponse` could not be converted to `HTTPURLResponse`.
    case notHTTPResponse(URLResponse)

    /// Returned `URLResponse` was nil
    case noResponse(url: URL?)

    /// Platform does not support streaming.
    case streamingNotSupported
}

extension HTTPResponse {
    init(_ urlResponse: URLResponse) throws {
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLSessionTransportError.notHTTPResponse(urlResponse)
        }
        var headerFields = HTTPFields()
        for (headerName, headerValue) in httpResponse.allHeaderFields {
            guard let rawName = headerName as? String, let name = HTTPField.Name(rawName),
                  let value = headerValue as? String else { continue }
            headerFields[name] = value
        }
        self.init(status: .init(code: httpResponse.statusCode), headerFields: headerFields)
    }
}

extension URLRequest {
    init(_ request: HTTPRequest, baseURL: URL) throws {
        guard var baseUrlComponents = URLComponents(string: baseURL.absoluteString),
              let requestUrlComponents = URLComponents(string: request.path ?? "") else {
            throw URLSessionTransportError.invalidRequestURL(path: request.path ?? "<nil>",
                                                             method: request.method,
                                                             baseURL: baseURL)
        }

        let path = requestUrlComponents.percentEncodedPath
        baseUrlComponents.percentEncodedPath += path
        baseUrlComponents.percentEncodedQuery = requestUrlComponents.percentEncodedQuery
        guard let url = baseUrlComponents.url else {
            throw URLSessionTransportError.invalidRequestURL(path: path, method: request.method, baseURL: baseURL)
        }
        self.init(url: url)
        self.httpMethod = request.method.rawValue
        for header in request.headerFields {
            self.setValue(header.value, forHTTPHeaderField: header.name.canonicalName)
        }
    }
}

// MARK: - URLSessionTransportError + LocalizedError

extension URLSessionTransportError: LocalizedError {
    /// A localized message describing what error occurred.
    var errorDescription: String? { description }
}

// MARK: - URLSessionTransportError + CustomStringConvertible

extension URLSessionTransportError: CustomStringConvertible {
    /// A textual representation of this instance.
    var description: String {
        switch self {
        case let .invalidRequestURL(path: path, method: method, baseURL: baseURL):
            return
                "Invalid request URL from request path: \(path), method: \(method), relative to base URL: \(baseURL.absoluteString)"
        case let .notHTTPResponse(response):
            return "Received a non-HTTP response, of type: \(String(describing: type(of: response)))"
        case let .noResponse(url): return "Received a nil response for \(url?.absoluteString ?? "<nil URL>")"
        case .streamingNotSupported: return "Streaming is not supported on this platform"
        }
    }
}
