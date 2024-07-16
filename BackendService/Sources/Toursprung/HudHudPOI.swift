//
//  HudHudPOI.swift
//  BackendService
//
//  Created by patrick on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//
// swiftlint:disable init_usage

import CoreLocation
import Foundation
import OpenAPIURLSession
import SFSafeSymbols

// generic errors that could come from any API
enum OpenAPIClientError: Error {
    case notFound
    case undocumentedAnswer(status: Int, body: String?)
    case unexpectedType(body: String)
}

// MARK: - HudHudClientError

// errors specific to our backend
enum HudHudClientError: Error {
    case poiIDNotFound
    
}

public struct HudHudPOI: POIServiceProtocol {
    
    public init() {
    }
    
    public static var serviceName = "HudHud"
    public func lookup(id: String, prediction: Any) async throws -> [ResolvedItem] {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport())	// swiftlint:disable:this force_unwrapping
        
        let response = try await client.getPoi(path: .init(id: id), headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let url: URL?
                if let websiteString = jsonResponse.data.website {
                    url = URL(string: websiteString)
                } else {
                    url = nil
                }
                var mediaURLsList = jsonResponse.data.media_urls?.map { MediaURLs(type: $0._type, url: $0.url) }
                return [ResolvedItem(id: jsonResponse.data.id, title: jsonResponse.data.name, subtitle: jsonResponse.data.address, category: jsonResponse.data.category, symbol: .pin, type: .appleResolved, coordinate: CLLocationCoordinate2D(latitude: jsonResponse.data.coordinates.lat, longitude: jsonResponse.data.coordinates.lon), phone: jsonResponse.data.phone_number, website: url, rating: jsonResponse.data.rating, ratingsCount: jsonResponse.data.ratings_count, isOpen: jsonResponse.data.is_open, mediaURLs: mediaURLsList)]
            }
        case .notFound:
            throw HudHudClientError.poiIDNotFound
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }
    
    public func predict(term: String, coordinates: CLLocationCoordinate2D?) async throws -> [AnyDisplayableAsRow] {
        try await Task.sleep(nanoseconds: 190 * NSEC_PER_MSEC)
        try Task.checkCancellation()
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport())	// swiftlint:disable:this force_unwrapping
        
        let response = try await client.getTypeahead(query: .init(query: term, lat: coordinates?.latitude, lon: coordinates?.longitude), headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
            
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let jsonResponse):
                let something: [AnyDisplayableAsRow] = jsonResponse.data.compactMap { somethingElse in
					guard let id = somethingElse.id else { return nil }
					
					let title = somethingElse.name
					guard let subtitle = somethingElse.address else { return nil }
					
                    return AnyDisplayableAsRow(PredictionItem(id: id, title: title, subtitle: subtitle, type: .hudhud))
                }
                return something
            }
        case .undocumented(statusCode: let statusCode, let payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }
}
// swiftlint:enable init_usage
