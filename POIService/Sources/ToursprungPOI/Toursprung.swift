//
//  Toursprung.swift
//  Navigation
//
//  Created by Patrick Kladek on 06.03.24.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre

public typealias JSONDictionary = [String: Any]

// MARK: - Toursprung

public class Toursprung {

	enum ToursprungError: LocalizedError {
		case invalidUrl
		case invalidResponse

		var errorDescription: String? {
			switch self {
			case .invalidUrl:
				return "Calculating route failed"
			case .invalidResponse:
				return "Calculating route failed"
			}
		}

		var failureReason: String? {
			switch self {
			case .invalidUrl:
				return "Calculating route failed because url can't be created"
			case .invalidResponse:
				return "Hudhud responded with invalid route"
			}
		}

		var recoverySuggestion: String? {
			switch self {
			case .invalidUrl:
				return "Retry with another destination"
			case .invalidResponse:
				return "Update the app or retry with another destination"
			}
		}

		var helpAnchor: String? {
			switch self {
			case .invalidUrl:
				return "Search for another location and start navigation to there"
			case .invalidResponse:
				return "Go to the AppStore and download the newest version of the App. Alternatively search for another location and start navigation to there."
			}
		}
	}

	public typealias RouteCompletionHandler = (_ waypoints: [Waypoint]?, _ routes: [Route]?, _ error: Error?) -> Void

	public static let shared = Toursprung()

	// MARK: - Lifecycle

	public init() {}

	// MARK: - Public

	public struct RouteCalculationResult {
		public let waypoints: [Waypoint]
		public let routes: [Route]
	}

	@discardableResult
	public func calculate(_ options: RouteOptions) async throws -> RouteCalculationResult {
		let url = try options.url

		let answer: (data: Data, response: URLResponse) = try await URLSession.shared.data(from: url)
		let json: JSONDictionary

		guard answer.response.mimeType == "application/json" else {
			throw ToursprungError.invalidResponse
		}

		do {
			json = try JSONSerialization.jsonObject(with: answer.data, options: []) as? [String: Any] ?? [:]
		} catch {
			throw ToursprungError.invalidResponse
		}

		let apiStatusCode = json["code"] as? String
		let apiMessage = json["message"] as? String
		guard (apiStatusCode == nil && apiMessage == nil) || apiStatusCode == "Ok" else {
			throw ToursprungError.invalidResponse
		}

		let response = options.response(from: json)
		for route in response.routes {
			route.routeIdentifier = json["uuid"] as? String
		}

		return .init(waypoints: response.waypoint, routes: response.routes)
	}
}

// MARK: - Private

private extension RouteOptions {

	var url: URL {
		get throws {
			let stops = self.waypoints.map { "\($0.coordinate.longitude),\($0.coordinate.latitude)" }.joined(separator: ";")

			var components = URLComponents()
			components.scheme = "https"
			components.host = "gh.maptoolkit.net"
			components.path = "/navigate/directions/v5/gh/car/\(stops)"
			components.queryItems = [
				URLQueryItem(name: "access_token", value: ""),
				URLQueryItem(name: "alternatives", value: "false"),
				URLQueryItem(name: "geometries", value: "polyline6"),
				URLQueryItem(name: "overview", value: "full"),
				URLQueryItem(name: "steps", value: "true"),
				URLQueryItem(name: "continue_straight", value: "true"),
				URLQueryItem(name: "annotations", value: "congestion,distance"),
				URLQueryItem(name: "language", value: "ar"),
				URLQueryItem(name: "roundabout_exits", value: "true"),
				URLQueryItem(name: "voice_instructions", value: "true"),
				URLQueryItem(name: "banner_instructions", value: "true"),
				URLQueryItem(name: "voice_units", value: "metric")
			]
			guard let url = components.url else {
				throw Toursprung.ToursprungError.invalidUrl
			}

			return url
		}
	}

	func response(from json: JSONDictionary) -> (waypoint: [Waypoint], routes: [Route]) {
		var namedWaypoints: [Waypoint] = []
		if let jsonWaypoints = (json["waypoints"] as? [JSONDictionary]) {
			namedWaypoints = zip(jsonWaypoints, self.waypoints).compactMap { api, local -> Waypoint? in
				guard let location = api["location"] as? [Double] else {
					return nil
				}

				let coordinate = CLLocationCoordinate2D(geoJSON: location)
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

public extension CLLocationCoordinate2D {

	init(geoJSON array: [Double]) {
		assert(array.count == 2)
		self.init(latitude: array[1], longitude: array[0])
	}

	init(geoJSON point: JSONDictionary) {
		assert(point["type"] as? String == "Point")
		self.init(geoJSON: point["coordinates"] as? [Double] ?? [])
	}

	static func coordinates(geoJSON lineString: JSONDictionary) -> [CLLocationCoordinate2D] {
		let type = lineString["type"] as? String
		assert(type == "LineString" || type == "Point")
		let coordinates = lineString["coordinates"] as? [[Double]] ?? []
		return coordinates.map { self.init(geoJSON: $0) }
	}
}
