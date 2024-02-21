//
//  ToursprungPOI.swift
//  ToursprungPOI
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import POIService
import CoreLocation
import MapKit

public actor ToursprungPOI: POIServiceProtocol {

	enum GeocoderError: Error, LocalizedError {
		case buildingURL
		case decodingError

		var errorDescription: String? {
			switch self {
			case .buildingURL:
				"Can't transform Input into URL."
			case .decodingError:
				"HudHud responded with invalid format."
			}
		}
	}

	private let session: URLSession = .shared

	// MARK: - Lifecycle

	public init() {

	}

	// MARK: - POIServiceProtocol

	public static var serviceName: String = "Apple"

	public func predict(term: String) async throws -> [Row] {
		return try await self.search(term: term)
	}

	public func lookup(prediction: PredictionResult) async throws -> [Row] {
		return []
	}
}

// MARK: - Private

private extension ToursprungPOI {

	func search(term: String) async throws -> [Row] {
		// "https://geocoder.maptoolkit.net/search?<params>"

		var components = URLComponents()
		components.scheme = "https"
		components.host = "geocoder.maptoolkit.net"
		components.path = "/search"
		components.queryItems = [
			URLQueryItem(name: "q", value: term),
			URLQueryItem(name: "countrycodes", value: "sa,at"),
			URLQueryItem(name: "language", value: "en"),
			URLQueryItem(name: "limit", value: "50"),
			URLQueryItem(name: "api_key", value: "hudhud")
		]
		guard let url = components.url else {
			throw GeocoderError.buildingURL
		}

		let request = URLRequest(url: url)
		guard let (data, response) = try await self.session.data(for: request) as? (Data, HTTPURLResponse) else {
			throw GeocoderError.decodingError
		}
		guard response.statusCode == 200 else {
			// parse error response
			throw GeocoderError.decodingError
		}

		let decoder = JSONDecoder()
		let poiElementss = try decoder.decode([POIElement].self, from: data)
		let pois = poiElementss.compactMap {
			return POIService.POI(element: $0)
		}
		return pois.map {
			return Row(toursprung: $0)
		}
	}
}

public extension POI {

	convenience init?(element: POIElement) {
		guard let lat = Double(element.lat),
			  let lon = Double(element.lon) else { return nil }

		let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

		self.init(title: element.displayName,
				  subtitle: element.address.description,
				  locationCoordinate: coordinate,
				  type: element.type)

		let mirror = Mirror(reflecting: element)
		mirror.children.forEach { child in
			guard let label = child.label else { return }

			self.userInfo[label] = child.value as? AnyHashable
		}
	}
}

public extension POIElement {

	static let starbucksKualaLumpur = POIElement(placeID: 374426437,
														licence: "Data © OpenStreetMap contributors, ODbL 1.0. https://osm.org/copyright",
														osmType: "node",
														osmID: 11363949513,
														boundingbox: ["3.177196", "3.177296", "101.7506882", "101.7507882"],
														lat: "3.177246",
														lon: "101.7507382",
														displayName: "Starbucks, Kuala Lumpur, Malaysia",
														poiClass: "amenity",
														type: "cafe",
														importance: 0.6758606469435616,
														address: Address(hamlet: nil,
																		 county: nil,
																		 state: nil,
																		 iso31662Lvl4: "MY-14",
																		 country: "Malaysia",
																		 countryCode: "my",
																		 town: nil,
																		 postcode: "54200",
																		 village: nil,
																		 iso31662Lvl6: nil,
																		 municipality: nil,
																		 region: nil,
																		 natural: nil,
																		 stateDistrict: nil,
																		 city: "Kuala Lumpur",
																		 road: "Jalan Taman Setiawangsa",
																		 quarter: nil,
																		 suburb: "Setiawangsa",
																		 iso31662Lvl3: nil),
														category: "poi")
}
