//
//  RoutingError.swift
//  HudHud
//
//  Created by Ali Hilal on 29/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - RoutingError

enum RoutingError: Error {
    case configuration(ConfigurationError)
    case network(NetworkError)
    case parsing(ParsingError)
    case routing(RoutingAPIError)

    // MARK: Nested Types

    enum ConfigurationError {
        case invalidURL(message: String?)
        case invalidConfiguration(message: String?)
    }

    enum NetworkError {
        case invalidResponseType
        case invalidMimeType
        case serverError(statusCode: Int, message: String?)
        case clientError(statusCode: Int, message: String?)
        case unexpectedStatus(statusCode: Int, message: String?)
    }

    enum ParsingError {
        case invalidJSON
        case osrmParsingError(message: String?)
    }

    enum RoutingAPIError {
        case unauthorized(message: String?)
        case forbidden(message: String?)
        case noRoute(message: String?)
        case noSegment(message: String?)
        case invalidInput(message: String?)
        case profileNotFound(message: String?)
        case unknown(code: String, message: String?)
    }
}

// MARK: - LocalizedError

extension RoutingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .configuration(error):
            switch error {
            case let .invalidURL(message):
                return "Failed to create routing URL: \(message ?? "Unknown error")"
            case let .invalidConfiguration(message):
                return "Invalid routing configuration: \(message ?? "Unknown error")"
            }
        case let .network(error):
            switch error {
            case .invalidResponseType:
                return "Invalid response type from routing server"
            case .invalidMimeType:
                return "Invalid response format from routing server"
            case let .serverError(code, message):
                return "Server error occurred (Status \(code)): \(message ?? "No details available")"
            case let .clientError(code, message):
                return "Client error occurred (Status \(code)): \(message ?? "No details available")"
            case let .unexpectedStatus(code, message):
                return "Unexpected response status (Status \(code)): \(message ?? "No details available")"
            }
        case let .parsing(error):
            switch error {
            case .invalidJSON:
                return "Failed to parse routing response"
            case let .osrmParsingError(message):
                return "Failed to parse OSRM response: \(message ?? "Unknown error")"
            }
        case let .routing(error):
            switch error {
            case let .unauthorized(message):
                return "Not authorized: \(message ?? "Unknown error")"
            case let .forbidden(message):
                return "Access forbidden: \(message ?? "Unknown error")"
            case let .noRoute(message):
                return "No route found: \(message ?? "Unknown error")"
            case let .noSegment(message):
                return "No segment found: \(message ?? "Unknown error")"
            case let .invalidInput(message):
                return "Invalid input: \(message ?? "Unknown error")"
            case let .profileNotFound(message):
                return "Profile not found: \(message ?? "Unknown error")"
            case let .unknown(code, message):
                return "Unknown routing error (\(code)): \(message ?? "Unknown error")"
            }
        }
    }
}
