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
import SwiftUI

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

public enum DisplayableRow: Hashable, Identifiable {
    case category(Category)
    case resolvedItem(ResolvedItem)
    case predictionItem(PredictionItem)
    
    public var resolvedItem: ResolvedItem? {
        switch self {
        case .category, .predictionItem:
            nil
        case .resolvedItem(let resolvedItem):
            resolvedItem
        }
    }
    
    public var id: String {
        switch self {
        case .category(let category):
            category.name
        case .resolvedItem(let resolvedItem):
            resolvedItem.id
        case .predictionItem(let predictionItem):
            predictionItem.id
        }
    }
    
    public func resolve(in provider: ApplePOI) async throws -> [DisplayableRow] {
        guard case let .apple(completion) = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: completion)
        let mapped = resolved.map {
            DisplayableRow.resolvedItem($0)
        }
        return mapped
    }
    
    public func resolve(in provider: HudHudPOI) async throws -> [DisplayableRow] {
        guard case .hudhud = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: self)
        let mapped = resolved.map {
            DisplayableRow.resolvedItem($0)
        }
        return mapped
    }
    
    private var type: PredictionResult? {
        switch self {
        case .category:
            nil
        case .resolvedItem(let resolvedItem):
            resolvedItem.type
        case .predictionItem(let predictionItem):
            predictionItem.type
        }
    }
}

public struct Category: Hashable {
    public let name: String
    public let icon: SFSymbol
    public let color: Color
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
                return [ResolvedItem(id: jsonResponse.data.id, title: jsonResponse.data.name, subtitle: jsonResponse.data.address, category: jsonResponse.data.category, symbol: .pin, type: .appleResolved, coordinate: CLLocationCoordinate2D(latitude: jsonResponse.data.coordinates.lat, longitude: jsonResponse.data.coordinates.lon), color: Color(.systemRed), phone: jsonResponse.data.phone_number, website: url)]
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
    
    public func predict(term: String, coordinates: CLLocationCoordinate2D?) async throws -> [DisplayableRow] {
        try await Task.sleep(nanoseconds: 190 * NSEC_PER_MSEC)
        try Task.checkCancellation()
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport())	// swiftlint:disable:this force_unwrapping
        
        let response = try await client.getTypeahead(query: .init(query: term, lat: coordinates?.latitude, lon: coordinates?.longitude), headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
            
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let jsonResponse):
                let something: [DisplayableRow] = jsonResponse.data.compactMap { somethingElse in
                    // we need to parse this symbol from the backend, and we cannot do it in a type safe way
                    let icon = SFSymbol(rawValue: somethingElse.ios_category_icon.name) // swiftlint:disable:this sf_symbol_init
                    switch somethingElse._type {
                    case .category:
                        return .category(Category(
                            name: somethingElse.name,
                            icon: icon,
                            color: somethingElse.ios_category_icon.color.swiftUIColor
                        ))
                    case .poi:
                        if let id = somethingElse.id,
                           let subtitle = somethingElse.address,
                           let latitude = somethingElse.coordinates?.lat,
                           let longitude = somethingElse.coordinates?.lon {
                            let title = somethingElse.name
                            return .resolvedItem(ResolvedItem(
                                id: id,
                                title: title,
                                subtitle: subtitle,
                                category: somethingElse.category,
                                symbol: icon,
                                type: .hudhud,
                                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                color: somethingElse.ios_category_icon.color.swiftUIColor
                            ))
                        } else {
                            assertionFailure("should have all the data here")
                        }
                        return nil
                    }
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

import SwiftUI

extension Components.Schemas.TypeaheadItem.ios_category_iconPayload.colorPayload {
    var swiftUIColor: Color {
        switch self {
        case .systemGray:
            Color(.systemGray)
        case .systemGray2:
            Color(.systemGray2)
        case .systemGray3:
            Color(.systemGray3)
        case .systemGray4:
            Color(.systemGray4)
        case .systemGray5:
            Color(.systemGray5)
        case .systemGray6:
            Color(.systemGray6)
        case .systemRed:
            Color(.systemRed)
        case .systemGreen:
            Color(.systemGreen)
        case .systemBlue:
            Color(.systemBlue)
        case .systemOrange:
            Color(.systemOrange)
        case .systemYellow:
            Color(.systemYellow)
        case .systemPink:
            Color(.systemPink)
        case .systemPurple:
            Color(.systemPurple)
        case .systemTeal:
            Color(.systemTeal)
        case .systemIndigo:
            Color(.systemIndigo)
        case .systemBrown:
            Color(.systemBrown)
        case .systemMint:
            Color(.systemMint)
        case .systemCyan:
            Color(.systemCyan)
        }
    }
}
