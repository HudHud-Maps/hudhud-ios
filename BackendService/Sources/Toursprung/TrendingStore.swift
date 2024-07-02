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
    
    @Published public var trendingPOIs: [ResolvedItem]?
    @Published public var lastError: Error?
    
    public func getTrendingPOIs(page: Int, limit: Int, coordinates: CLLocationCoordinate2D?) async throws -> [ResolvedItem] {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport())
        let response = try await client.listTrendingPois(query: .init(page: page, limit: limit, lat: coordinates?.latitude, lon: coordinates?.longitude),headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            
            case .json(let jsonResponse):
                let resolvedItem: [ResolvedItem] = jsonResponse.data.compactMap { item in
                    
                    guard let ratingCount = item.ratings_count else { return ResolvedItem.artwork }
                    return ResolvedItem(id: item.id, title: item.name, subtitle: item.category, category: item.category, symbol: .pin, type: .hudhud, coordinate: CLLocationCoordinate2D(latitude: item.coordinates.lat, longitude: item.coordinates.lon), phone: nil, website: nil, rating: item.rating, ratingCount: ratingCount, trendingImage: item.trending_image_url)
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
