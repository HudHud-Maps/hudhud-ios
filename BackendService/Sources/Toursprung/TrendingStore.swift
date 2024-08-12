//
//  TrendingStore.swift
//	BackendService
//
//  Created by Fatima Aljaber on 06/06/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
// swiftlint:disable init_usage

import CoreLocation
import Foundation
import MapKit
import OpenAPIURLSession
import SwiftUI

public class TrendingStore: ObservableObject {

    @Published public var trendingPOIs: [ResolvedItem]?
    @Published public var lastError: Error?

    public func getTrendingPOIs(page: Int, limit: Int, coordinates: CLLocationCoordinate2D?, baseURL: String) async throws -> [ResolvedItem] {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)
        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)
        let transport = URLSessionTransport(configuration: transportConfiguration)

        let response = try await ClientClass.makeClient(using: baseURL, transport: transport).listTrendingPois(query: .init(page: page, limit: limit, lat: coordinates?.latitude, lon: coordinates?.longitude), headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let resolvedItem: [ResolvedItem] = jsonResponse.data.compactMap { item in

                    guard let ratingCount = item.ratings_count else { return ResolvedItem.artwork }
                    return ResolvedItem(id: item.id, title: item.name, subtitle: item.category, category: item.category, symbol: .pin, type: .hudhud, coordinate: CLLocationCoordinate2D(latitude: item.coordinates.lat, longitude: item.coordinates.lon), color: .systemRed, phone: nil, website: nil, rating: item.rating, ratingsCount: ratingCount, trendingImage: item.trending_image_url)
                }
                return resolvedItem
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            self.lastError = OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }

    // MARK: - Lifecycle

    public init() {}

}

// swiftlint:enable init_usage
