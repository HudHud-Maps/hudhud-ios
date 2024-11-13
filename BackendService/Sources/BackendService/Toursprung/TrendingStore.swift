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
import OpenAPIRuntime
import SwiftUI

@MainActor
public class TrendingStore: ObservableObject {

    // MARK: Properties

    @Published public var trendingPOIs: [ResolvedItem]?
    @Published public var lastError: Error?

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func getTrendingPOIs(page _: Int, limit _: Int, coordinates: CLLocationCoordinate2D?, baseURL: String) async throws -> [ResolvedItem] {
        let client = Client.makeClient(using: baseURL)
        let response = try await client.listTrendingPois(query: .init(lat: coordinates?.latitude, lon: coordinates?.longitude),
                                                         headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let resolvedItem: [ResolvedItem] = jsonResponse.data.compactMap { item in
                    guard let ratingCount = item.ratings_count else { return ResolvedItem.artwork }

                    return ResolvedItem(id: item.id,
                                        title: item.name,
                                        subtitle: item.category,
                                        category: item.category,
                                        symbol: .pin,
                                        type: .hudhud,
                                        coordinate: CLLocationCoordinate2D(latitude: item.coordinates.lat, longitude: item.coordinates.lon),
                                        phone: nil,
                                        website: nil,
                                        rating: item.rating,
                                        ratingsCount: ratingCount,
                                        trendingImage: item.trending_image_url)
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
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message)
        }
    }

}

// swiftlint:enable init_usage
