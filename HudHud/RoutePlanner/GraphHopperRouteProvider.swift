//
//  GraphHopperRouteProvider.swift
//  HudHud
//
//  Created by Ali Hilal on 29/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import APIClient
import BackendService
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import OSLog

// MARK: - GraphHopperRouteProvider

struct GraphHopperRouteProvider: CustomRouteProvider, RoutingService {

    // MARK: Properties

    private let osrmParser: any RouteResponseParser

    // MARK: Lifecycle

    init(polylinePrecision: UInt32 = 6) {
        self.osrmParser = createOsrmResponseParser(polylinePrecision: polylinePrecision)
    }

    // MARK: Functions

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

        let (data, response) = try await APIClient.urlSession.data(from: url)
        try self.validateResponse(response, data: data)

        let json = try parseJSON(from: data)
        try handleAPIStatus(from: json)

        return try self.osrmParser.parseResponse(response: data)
    }

    private func buildURL(for stops: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = DebugStore().routingHost
        components.path = "/navigate/directions/v5/gh/car/\(stops)"
        components.queryItems = RoutingOptions().queryItems

        guard let url = components.url else {
            throw RoutingError.configuration(.invalidURL(message: "Couldn't create url from URLComponents"))
        }
        return url
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RoutingError.network(.invalidResponseType)
        }

        guard httpResponse.mimeType == "application/json" else {
            throw RoutingError.network(.invalidMimeType)
        }

        if !(200 ... 299).contains(httpResponse.statusCode) {
            let apiMessage = (try? self.parseJSON(from: data)["message"] as? String) ?? "No message provided"

            switch httpResponse.statusCode {
            case 400 ... 499:
                throw RoutingError.network(.clientError(statusCode: httpResponse.statusCode, message: apiMessage))
            case 500 ... 599:
                throw RoutingError.network(.serverError(statusCode: httpResponse.statusCode, message: apiMessage))
            default:
                throw RoutingError.network(.unexpectedStatus(statusCode: httpResponse.statusCode, message: apiMessage))
            }
        }
    }

    private func parseJSON(from data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw RoutingError.parsing(.invalidJSON)
        }
        return json
    }

    private func handleAPIStatus(from json: [String: Any]) throws {
        guard let apiStatusCode = json["code"] as? String,
              let apiMessage = json["message"] as? String else {
            return
        }

        switch apiStatusCode {
        case "Ok":
            return
        case "InvalidInput":
            throw RoutingError.routing(.invalidInput(message: apiMessage))
        case "Not Authorized - No Token", "Not Authorized - Invalid Token":
            throw RoutingError.routing(.unauthorized(message: apiMessage))
        case "Forbidden":
            throw RoutingError.routing(.forbidden(message: apiMessage))
        case "ProfileNotFound":
            throw RoutingError.routing(.profileNotFound(message: apiMessage))
        case "NoSegment":
            throw RoutingError.routing(.noSegment(message: apiMessage))
        case "NoRoute":
            throw RoutingError.routing(.noRoute(message: apiMessage))
        default:
            throw RoutingError.routing(.unknown(code: apiStatusCode, message: apiMessage))
        }
    }
}
