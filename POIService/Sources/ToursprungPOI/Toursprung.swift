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

	public static let shared = Toursprung()

	// MARK: - Lifecycle

	public init() {}

	// MARK: - Public

	@discardableResult
	public func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> URLSessionDataTask {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "gh.maptoolkit.net"
		components.path = "/navigate/directions/v5/gh/car/\(options.waypoints[0].coordinate.longitude),\(options.waypoints[0].coordinate.latitude);\(options.waypoints[1].coordinate.longitude),\(options.waypoints[1].coordinate.latitude)"
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
		let url = components.url!

		let task = self.dataTask(with: url, completionHandler: { json in
			let response = options.response(from: json)
			if let routes = response.routes {
				for route in routes {
					route.routeIdentifier = json["uuid"] as? String
				}
			}
			completionHandler(response.waypoint, response.routes, nil)
		}) { error in
			completionHandler(nil, nil, error)
		}
		task.resume()
		return task
	}

	public func preview(from json: JSONDictionary) -> Route {
		let waypoints: [Waypoint] = (json["waypoints"] as! [JSONDictionary]).map {
			let waypoint = $0
			let location = waypoint["location"] as! [Double]
			let coordinate = CLLocationCoordinate2D(geoJSON: location)
			let name: String = (waypoint["name"] as? String) ?? ""
			return Waypoint(coordinate: coordinate, name: name)
		}
		print("waypoints: \(waypoints)")

		let options = RouteOptions(waypoints: waypoints)

		let routes = (json["routes"] as? [JSONDictionary])?.map {
			Route(json: $0, waypoints: waypoints, options: options)
		}
		let route = routes!.first!
		return route
	}
}

// MARK: - Private

private extension Toursprung {

	func dataTask(with url: URL, data: Data? = nil, completionHandler: @escaping (_ json: [String: Any]) -> Void, errorHandler _: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
		let request = URLRequest(url: url)

		return URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
			var json: [String: Any] = [:]
			if let data, response?.mimeType == "application/json" {
				do {
					json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
				} catch {
					assertionFailure("Invalid data")
				}
			}

			let apiStatusCode = json["code"] as? String
			let apiMessage = json["message"] as? String
			guard data != nil, error == nil, (apiStatusCode == nil && apiMessage == nil) || apiStatusCode == "Ok" else {
				fatalError()
			}

			DispatchQueue.main.async {
				completionHandler(json)
			}
		}
	}
}

private extension RouteOptions {

	func response(from json: JSONDictionary) -> (waypoint: [Waypoint]?, routes: [Route]?) {
		var namedWaypoints: [Waypoint]?
		if let jsonWaypoints = (json["waypoints"] as? [JSONDictionary]) {
			namedWaypoints = zip(jsonWaypoints, self.waypoints).map { api, local -> Waypoint in
				let location = api["location"] as! [Double]
				let coordinate = CLLocationCoordinate2D(geoJSON: location)
				let possibleAPIName = api["name"] as? String
				let apiName = possibleAPIName?.nonEmptyString
				return Waypoint(coordinate: coordinate, name: local.name ?? apiName)
			}
		}

		let waypoints = namedWaypoints ?? self.waypoints

		let routes = (json["routes"] as? [JSONDictionary])?.map {
			Route(json: $0, waypoints: waypoints, options: self)
		}
		return (waypoints, routes)
	}
}

public extension CLLocationCoordinate2D {

	init(geoJSON array: [Double]) {
		assert(array.count == 2)
		self.init(latitude: array[1], longitude: array[0])
	}

	init(geoJSON point: JSONDictionary) {
		assert(point["type"] as? String == "Point")
		self.init(geoJSON: point["coordinates"] as! [Double])
	}

	static func coordinates(geoJSON lineString: JSONDictionary) -> [CLLocationCoordinate2D] {
		let type = lineString["type"] as? String
		assert(type == "LineString" || type == "Point")
		let coordinates = lineString["coordinates"] as! [[Double]]
		return coordinates.map { self.init(geoJSON: $0) }
	}
}
