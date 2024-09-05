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

struct HudHudGraphHopperRouteProvider: CustomRouteProvider {
    func getRoutes(userLocation: FerrostarCoreFFI.UserLocation, waypoints: [FerrostarCoreFFI.Waypoint]) async throws -> [FerrostarCoreFFI.Route] {
        print("Actually getting new routes...")
        var currentLocationString = "\(userLocation.coordinates.lng),\(userLocation.coordinates.lat)"
        let stops = waypoints.map { "\($0.coordinate.lng),\($0.coordinate.lat)" }.joined(separator: ";")

        var components = URLComponents()
        components.scheme = "https"
        components.host = DebugStore().routingHost
        components.path = "/navigate/directions/v5/gh/car/\(currentLocationString);\(stops)"
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

        let answer: (data: Data, response: URLResponse) = try await URLSession.shared.data(from: url)

        guard answer.response.mimeType == "application/json" else {
            throw RoutingService.ToursprungError.invalidResponse(message: "MIME Type not matching application/json")
        }

        let osrmParser = createOsrmResponseParser(polylinePrecision: 6)
        return try osrmParser.parseResponse(response: answer.data)
    }

}
