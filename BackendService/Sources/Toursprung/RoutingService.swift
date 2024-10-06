//
//  RoutingService.swift
//  BackendService
//
//  Created by Patrick Kladek on 06.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import OSLog

public typealias JSONDictionary = [String: Any]

// MARK: - RoutingService

public class RoutingService {

    public typealias RouteCompletionHandler = (_ waypoints: [Waypoint]?, _ routes: [Route]?, _ error: Error?) -> Void

    // MARK: Nested Types

    // MARK: - Public

    public struct RouteCalculationResult: Equatable, Hashable, Encodable, Decodable {

        // MARK: Properties

        public let waypoints: [Waypoint]
        public var routes: [Route]

        // MARK: Lifecycle

        public init(from _: any Decoder) throws {
            // this is an empty implementation to support the NavPath workaround, as we never actually use
            // whats inside in RouteCalculationResult, we only want to know if its in the path.
            self.waypoints = []
            self.routes = []
        }

        public init(waypoints: [Waypoint], routes: [Route]) {
            self.waypoints = waypoints
            self.routes = routes
        }

        // MARK: Functions

        // MARK: - Public

        public func encode(to encoder: any Encoder) throws {
            // this is an empty implementation to support the NavPath workaround, as we never actually use
            // whats inside in RouteCalculationResult, we only want to know if its in the path.

            var container = encoder.unkeyedContainer()
            try container.encode(true) // we need to encode something, else the encoder throws an error that it didnt do anything
        }
    }

    public enum ToursprungError: LocalizedError, Equatable {
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

    // MARK: Static Properties

    public static let shared = RoutingService()

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    @discardableResult
    public func calculate(host: String, options: RouteOptions) async throws -> RouteCalculationResult {
        let url = try options.url(host: host)
        let answer: (data: Data, response: URLResponse) = try await URLSession.shared.data(from: url)
        let json: JSONDictionary

        guard answer.response.mimeType == "application/json" else {
            throw ToursprungError.invalidResponse(message: "MIME Type not matching application/json")
        }

        do {
            json = try JSONSerialization.jsonObject(with: answer.data, options: []) as? [String: Any] ?? [:]
        } catch let error as ToursprungError {
            throw ToursprungError.invalidResponse(message: "Route error occurred: \(error.localizedDescription)")
        }

        let apiStatusCode = json["code"] as? String
        let apiMessage = json["message"] as? String
        guard (apiStatusCode == nil && apiMessage == nil) || apiStatusCode == "Ok" else {
            switch apiStatusCode {
            case "InvalidInput":
                throw ToursprungError.invalidInput(message: apiMessage)
            case "Not Authorized - No Token":
                throw ToursprungError.notAuthorized(message: apiMessage)
            case "Not Authorized - Invalid Token":
                throw ToursprungError.notAuthorized(message: apiMessage)
            case "Forbidden":
                throw ToursprungError.forbidden(message: apiMessage)
            case "ProfileNotFound":
                throw ToursprungError.profileNotFound(message: apiMessage)
            case "NoSegment":
                throw ToursprungError.noSegment(message: apiMessage)
            case "NoRoute":
                throw ToursprungError.noRoute(message: apiMessage)
            default:
                throw ToursprungError.invalidResponse(message: nil)
            }
        }

        let response = try options.response(from: json)
        for route in response.routes {
            route.routeIdentifier = json["uuid"] as? String
        }
        guard let httpResponse = answer.response as? HTTPURLResponse else {
            throw ToursprungError.invalidResponse(message: "Unexpected response type")
        }
        let httpStatusCode = httpResponse.statusCode
        switch httpStatusCode {
        case 500 ... 599:
            throw ToursprungError.invalidResponse(message: "Server error HTTP status code: \(httpStatusCode)")
        case 200 ... 299:
            return RouteCalculationResult(waypoints: response.waypoint, routes: response.routes)
        default:
            throw ToursprungError.invalidResponse(message: "Server error occurred")
        }
    }
}

// MARK: - Private

private extension RouteOptions {

    func url(host: String) throws -> URL {
        let stops = self.waypoints.map { "\($0.coordinate.longitude),\($0.coordinate.latitude)" }.joined(separator: ";")

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/navigate/directions/v5/gh/car/\(stops)"
        components.queryItems = [
            URLQueryItem(name: "access_token", value: ""),
            URLQueryItem(name: "alternatives", value: "false"),
            URLQueryItem(name: "geometries", value: "polyline6"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "steps", value: "true"),
            URLQueryItem(name: "continue_straight", value: "true"),
            URLQueryItem(name: "annotations", value: "congestion,distance"),
            URLQueryItem(name: "language", value: Locale.preferredLanguages.first ?? "en-US"),
            URLQueryItem(name: "roundabout_exits", value: "true"),
            URLQueryItem(name: "voice_instructions", value: "true"),
            URLQueryItem(name: "banner_instructions", value: "true"),
            URLQueryItem(name: "voice_units", value: "metric")
        ]
        guard let url = components.url else {
            throw RoutingService.ToursprungError.invalidUrl(message: "Couldn't create url from URLComponents")
        }

        return url
    }

    func response(from json: JSONDictionary) throws -> (waypoint: [Waypoint], routes: [Route]) {
        var namedWaypoints: [Waypoint] = []
        if let jsonWaypoints = (json["waypoints"] as? [JSONDictionary]) {
            namedWaypoints = try zip(jsonWaypoints, self.waypoints).compactMap { api, local -> Waypoint? in
                guard let location = api["location"] as? [Double] else {
                    return nil
                }

                let coordinate = try CLLocationCoordinate2D(geoJSON: location)
                let possibleAPIName = api["name"] as? String
                let apiName = possibleAPIName?.nonEmptyString
                return Waypoint(coordinate: coordinate, name: local.name ?? apiName)
            }
        }

        let routes = (json["routes"] as? [JSONDictionary] ?? []).compactMap {
            Route(json: $0, waypoints: waypoints, options: self)
        }
        return (namedWaypoints, routes)
    }
}
