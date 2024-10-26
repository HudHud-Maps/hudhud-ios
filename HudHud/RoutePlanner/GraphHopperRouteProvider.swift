//
//  GraphHopperRouteProvider.swift
//  HudHud
//
//  Created by Ali Hilal on 19/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import OSLog

// MARK: - GraphHopperRouteProvider

struct GraphHopperRouteProvider: CustomRouteProvider, RoutingService {

    func getRoutes(
        userLocation: FerrostarCoreFFI.UserLocation,
        waypoints: [FerrostarCoreFFI.Waypoint]
    ) async throws -> [FerrostarCoreFFI.Route] {
        guard !waypoints.isEmpty else { return [] }
        var waypoints = waypoints
        guard let lastWaypoint = waypoints.popLast() else {
            return []
        }

        let firstWaypoint = Waypoint(coordinate: userLocation.coordinates, kind: .via)
        return try await self.calculateRoute(
            from: firstWaypoint,
            to: lastWaypoint,
            passingBy: waypoints
        )
    }

    func calculateRoute(
        from start: Waypoint,
        to end: Waypoint,
        passingBy waypoints: [Waypoint]
    ) async throws -> [Route] {
        let allWaypoints = [start] + waypoints + [end]
        let stops = allWaypoints.map { "\($0.coordinate.lng),\($0.coordinate.lat)" }.joined(separator: ";")
        let url = try buildURL(for: stops)
        Logger.routing.debug("Requesting route from \(url)")

        let (data, response) = try await URLSession.shared.data(from: url)

        try self.validateResponse(response)

        let json = try parseJSON(from: data)
        try handleAPIStatus(from: json)

        let osrmParser = createOsrmResponseParser(polylinePrecision: 6)
        let parsedRoutes = try osrmParser.parseResponse(response: data)
        return parsedRoutes
    }

    private func buildURL(for stops: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = DebugStore().routingHost
        components.path = "/navigate/directions/v5/gh/car/\(stops)"
        components.queryItems = RoutingOptions().queryItems

        guard let url = components.url else {
            throw ToursprungError.invalidUrl(message: "Couldn't create url from URLComponents")
        }
        return url
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ToursprungError.invalidResponse(message: "Unexpected response type")
        }

        guard httpResponse.mimeType == "application/json" else {
            throw ToursprungError.invalidResponse(message: "MIME Type not matching application/json")
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            if (500 ... 599).contains(httpResponse.statusCode) {
                throw ToursprungError.invalidResponse(message: "Server error HTTP status code: \(httpResponse.statusCode)")
            } else {
                throw ToursprungError.invalidResponse(message: "Server error occurred")
            }
        }
    }

    private func parseJSON(from data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw ToursprungError.invalidResponse(message: "Invalid JSON format")
        }
        return json
    }

    private func handleAPIStatus(from json: [String: Any]) throws {
        if let apiStatusCode = json["code"] as? String,
           let apiMessage = json["message"] as? String {
            try self.handleApiError(statusCode: apiStatusCode, message: apiMessage)
        }
    }

    private func handleApiError(statusCode: String, message: String) throws {
        switch statusCode {
        case "Ok":
            return
        case "InvalidInput":
            throw ToursprungError.invalidInput(message: message)
        case "Not Authorized - No Token", "Not Authorized - Invalid Token":
            throw ToursprungError.notAuthorized(message: message)
        case "Forbidden":
            throw ToursprungError.forbidden(message: message)
        case "ProfileNotFound":
            throw ToursprungError.profileNotFound(message: message)
        case "NoSegment":
            throw ToursprungError.noSegment(message: message)
        case "NoRoute":
            throw ToursprungError.noRoute(message: message)
        default:
            throw ToursprungError.invalidResponse(message: "Unknown API error: \(statusCode) - \(message)")
        }
    }
}

// MARK: - ToursprungError

enum ToursprungError: LocalizedError, Equatable {
    case invalidUrl(message: String?)
    case invalidResponse(message: String?)
    case noRoute(message: String?)
    case noSegment(message: String?)
    case forbidden(message: String?)
    case invalidInput(message: String?)
    case profileNotFound(message: String?)
    case notAuthorized(message: String?)

    // MARK: Computed Properties

    public var errorDescription: String? {
        switch self {
        case let .invalidUrl(message):
            return errorDescription(message: message, defaultMessage: "Calculating route failed")
        case let .invalidResponse(message):
            return errorDescription(message: message, defaultMessage: "Calculating route failed")
        case let .noRoute(message):
            return errorDescription(message: message, defaultMessage: "No route found.")
        case let .noSegment(message):
            return errorDescription(message: message, defaultMessage: "No segment found.")
        case let .forbidden(message):
            return errorDescription(message: message, defaultMessage: "Forbidden access.")
        case let .invalidInput(message):
            return errorDescription(message: message, defaultMessage: "Invalid input.")
        case let .profileNotFound(message: message):
            return errorDescription(message: message, defaultMessage: "ProfileNotFound")
        case let .notAuthorized(message: message):
            return errorDescription(message: message, defaultMessage: "NotAuthorized")
        }
    }

    public var failureReason: String? {
        switch self {
        case let .invalidUrl(message):
            return self.errorDescription(message: message, defaultMessage: "Calculating route failed because url can't be created")
        case let .invalidResponse(message):
            return self.errorDescription(message: message, defaultMessage: "Hudhud responded with invalid route")
        case let .noRoute(message):
            return self.errorDescription(message: message, defaultMessage: "No route found.")
        case let .noSegment(message):
            return self.errorDescription(message: message, defaultMessage: "No segment found.")
        case let .forbidden(message):
            return self.errorDescription(message: message, defaultMessage: "Forbidden access.")
        case let .invalidInput(message):
            return self.errorDescription(message: message, defaultMessage: "Invalid input.")
        case let .profileNotFound(message: message):
            return self.errorDescription(message: message, defaultMessage: "Profile Not Found")
        case let .notAuthorized(message: message):
            return self.errorDescription(message: message, defaultMessage: "Not Authorized")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidUrl:
            return "Retry with another destination"
        case .invalidResponse:
            return "Update the app or retry with another destination"
        case .noRoute:
            return "Retry with another destination"
        case .noSegment:
            return "Retry with another destination"
        case .forbidden:
            return "Forbidden access."
        case .invalidInput:
            return "Invalid input."
        case .profileNotFound:
            return "Profile Not Found"
        case .notAuthorized:
            return "Not Authorized"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .invalidUrl:
            return "Search for another location and start navigation to there"
        case .invalidResponse:
            return "Go to the AppStore and download the newest version of the App. Alternatively search for another location and start navigation to there."
        case .noRoute:
            return "Search for another location and start navigation to there"
        case .noSegment:
            return "Search for another location and start navigation to there"
        case .forbidden:
            return "Forbidden access"
        case .invalidInput:
            return "Invalid input"
        case .profileNotFound:
            return "Profile Not Found"
        case .notAuthorized:
            return "Not Authorized"
        }
    }

    // MARK: Functions

    // MARK: - Private

    private func errorDescription(message: String?, defaultMessage: String) -> String {
        var description = defaultMessage
        if let message {
            description += " \(message)"
        }
        return description
    }
}
