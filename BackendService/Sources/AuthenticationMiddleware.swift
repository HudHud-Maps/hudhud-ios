//
//  AuthenticationMiddleware.swift
//  BackendService
//
//  Created by Patrick Kladek on 09.10.24.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime

// MARK: - AuthenticationMiddleware

/// A client middleware that injects a value into the `Authorization` header field of the request.
struct AuthenticationMiddleware {

    // MARK: Properties

    /// The value for the `Authorization` header field.
    private let value: String

    // MARK: Lifecycle

    /// Creates a new middleware.
    /// - Parameter value: The value for the `Authorization` header field.
    init(authorizationHeaderFieldValue value: String) { self.value = value }
}

// MARK: - ClientMiddleware

extension AuthenticationMiddleware: ClientMiddleware {
    func intercept(_ request: HTTPRequest,
                   body: HTTPBody?,
                   baseURL: URL,
                   operationID _: String,
                   next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request

        if let token = try AuthProvider.shared.retrive() {
            request.headerFields[.authorization] = token.refreshToken
        }

        return try await next(request, body, baseURL)
    }
}
