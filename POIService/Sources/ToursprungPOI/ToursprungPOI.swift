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

final class ToursprungPOI: POIServiceProtocol {

    enum GeocoderError: Error {
        case buildingURL
        case decodingError
    }

    static let serviceName: String = "Toursprung"
    let session: URLSession = .shared

    // MARK: - ToursprungPOI

    func search(term: String) async throws -> [POI] {
        // "https://geocoder.maptoolkit.net/search?<params>"

        var components = URLComponents()
        components.scheme = "https"
        components.host = "geocoder.maptoolkit.net"
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: term),
            URLQueryItem(name: "countrycodes", value: "sa"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "limit", value: "10"),
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
        return pois.map {
            let coordinate = CLLocationCoordinate2D(latitude: Double($0.lat) ?? 0.0, 
                                                    longitude: Double($0.lon) ?? 0.0)
            return POIService.POI(name: $0.displayName,
                                  locationCoordinate: coordinate,
                                  type: $0.type) }
    }
}
