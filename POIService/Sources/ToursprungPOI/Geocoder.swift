//
//  Geocoder.swift
//  Toursprung
//
//  Created by Patrick Kladek on 31.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

class Geocoder {

	enum GeocoderError: Error {
		case buildingURL
		case decodingError
	}

	let session: URLSession

	// MARK: - Lifecycle

	init(session: URLSession) {
		self.session = session
	}

	// MARK: - Geocoder

	func search(term: String, limit: Int = 10, countryCode: String = "sa", language: String = Locale.current.language.minimalIdentifier) async throws -> [POIElement] {
		// "https://geocoder.maptoolkit.net/search?<params>"

		var components = URLComponents()
		components.scheme = "https"
		components.host = "geocoder.maptoolkit.net"
		components.path = "/search"
		components.queryItems = [
			URLQueryItem(name: "q", value: term),
			URLQueryItem(name: "countrycodes", value: countryCode),
			URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "limit", value: "\(limit)"),
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
		let pois = try decoder.decode([POIElement].self, from: data)
		return pois
	}
}
