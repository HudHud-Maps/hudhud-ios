//
//  TrendingStore.swift
//
//
//  Created by Fatima Aljaber on 06/06/2024.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import OpenAPIURLSession

public class TrendingStore: ObservableObject{
    
    @Published public var trendingPOIs : [ResolvedItem]?
    @Published public var lastError: Error?
    
    public func getTrendingPOIs(page: Int, limit: Int, coordinates: CLLocationCoordinate2D?) async throws -> [ResolvedItem] {
        let client = Client(serverURL: URL(string: "https://hudhud.sa")!, transport: URLSessionTransport())
        let response = try await client.listTrendingPois(query: .init(page: page, limit: limit, lat: coordinates?.latitude, lon: coordinates?.longitude),headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
                
            case .json(let jsonResponse):
                let resolvedItem: [ResolvedItem] = jsonResponse.data.compactMap { item in
                    
                    guard let id = item.id, let title = item.name, let subtitle = item.category, let lon = item.coordinates?.lon, let lat = item.coordinates?.lat, let rating = item.rating, let ratingCount = item.ratings_count, let trendingImage = item.trending_image_url, let distance = item.distance else { return ResolvedItem.artwork }
                    return ResolvedItem(id: id, title: title, subtitle: subtitle, category: subtitle, symbol: .pin, type: .hudhud, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), phone: nil, website: nil, rating: rating, ratingCount: ratingCount, trendingImage: trendingImage, distance: distance)
                }
                    return resolvedItem
                
            }
        case .undocumented(statusCode: let statusCode, let payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            self.lastError = OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }
    
    public init(){
        
    }
}
