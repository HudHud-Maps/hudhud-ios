//
//  GraphHopperRouteAdapter.swift
//  HudHud
//
//  Created by patrick on 04.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import OSLog

// MARK: - HudHudGraphHopperRouteProvider

struct HudHudGraphHopperRouteProvider: CustomRouteProvider {

    func getRoutes(waypoints: [FerrostarCoreFFI.Waypoint]) async throws -> [FerrostarCoreFFI.Route] {
        let stops = waypoints.map { "\($0.coordinate.lng),\($0.coordinate.lat)" }.joined(separator: ";")

        var components = URLComponents()
        components.scheme = "https"
        components.host = DebugStore().routingHost
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
            throw ToursprungError.invalidUrl(message: "Couldn't create url from URLComponents")
        }

        Logger.routing.debug("Requesting route from \(url)")
        let answer: (data: Data, response: URLResponse) = try await URLSession.shared.data(from: url)

        guard answer.response.mimeType == "application/json" else {
            throw ToursprungError.invalidResponse(message: "MIME Type not matching application/json")
        }

        let osrmParser = createOsrmResponseParser(polylinePrecision: 6)

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

        guard let httpResponse = answer.response as? HTTPURLResponse else {
            throw ToursprungError.invalidResponse(message: "Unexpected response type")
        }
        let httpStatusCode = httpResponse.statusCode
        switch httpStatusCode {
        case 500 ... 599:
            throw ToursprungError.invalidResponse(message: "Server error HTTP status code: \(httpStatusCode)")
        case 200 ... 299:
            let routes = try osrmParser.parseResponse(response: answer.data)
            let segments = routes.map {
                ($0.id, $0.extractCongestionSegments())
            }
            //            dump(routes.first?.geometryCLLocationCoordinate2D)
            dump(segments.first)
            return routes
        default:
            throw ToursprungError.invalidResponse(message: "Server error occurred")
        }
    }

    func getRoutes(userLocation: FerrostarCoreFFI.UserLocation, waypoints: [FerrostarCoreFFI.Waypoint]) async throws -> [FerrostarCoreFFI.Route] {
        // convert user location to first waypoint
        let firstWaypoint = Waypoint(coordinate: userLocation.coordinates, kind: .via)
        let allWaypoints = [firstWaypoint] + waypoints
        return try await self.getRoutes(waypoints: allWaypoints)
    }

    /*
     private func response(from json: JSONDictionary) throws -> (waypoint: [FerrostarCoreFFI.Waypoint], routes: [FerrostarCoreFFI.Route]) {
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
     */

}

// MARK: - ToursprungError

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

import CoreLocation

// MARK: - CongestionSegment

struct CongestionSegment {
    let level: String
    let geometry: [CLLocationCoordinate2D]
}

extension Route {
    var annotations: [ValhallaOsrmAnnotation] {
        let decoder = JSONDecoder()

        return steps
            .compactMap(\.annotations)
            .flatMap { annotations in
                annotations.compactMap { annotationString in
                    guard let data = annotationString.data(using: .utf8) else {
                        return nil
                    }
                    return try? decoder.decode(ValhallaOsrmAnnotation.self, from: data)
                }
            }
    }
}

extension Route {

    func extractCongestionSegments() -> [CongestionSegment] {
        var mergedSegments: [CongestionSegment] = []
        var currentSegment: CongestionSegment?
        var currentIndex = 0

        for annotation in self.annotations {
            guard let congestion = annotation.congestion else {
                continue
            }

            let startIndex = currentIndex
            let endIndex = startIndex + 1

            if endIndex >= geometry.count {
                break
            }

            let segmentGeometry = Array(geometry[startIndex ... endIndex])

            if let current = currentSegment,
               current.level == congestion,
               let lastSegment = current.geometry.last {
                currentSegment = CongestionSegment(
                    level: congestion,
                    geometry: current.geometry + [lastSegment]
                )
            } else {
                if let current = currentSegment {
                    mergedSegments.append(current)
                }
                currentSegment = CongestionSegment(
                    level: congestion,
                    geometry: segmentGeometry.map(\.clLocationCoordinate2D)
                )
            }

            currentIndex = endIndex
        }

        if let lastSegment = currentSegment {
            mergedSegments.append(lastSegment)
        }
        return mergedSegments
    }

    private func findEndIndex(startingFrom startIndex: Int, distance: Double) -> Int {
        var remainingDistance = distance
        var currentIndex = startIndex

        while currentIndex < geometry.count - 1, remainingDistance > 0 {
            let segmentDistance = geometry[currentIndex]
                .clLocationCoordinate2D
                .distance(
                    to: geometry[currentIndex + 1].clLocationCoordinate2D
                )
            if remainingDistance >= segmentDistance {
                remainingDistance -= segmentDistance
                currentIndex += 1
            } else {
                break
            }
        }

        return currentIndex
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}
