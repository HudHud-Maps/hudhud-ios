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
    public let systemColor: SystemColor
}

public enum SystemColor: RawRepresentable, Codable {
    public init?(rawValue: String) {
        switch rawValue {
        case "systemGray":
            self = .systemGray
        case "systemGray2":
            self = .systemGray2
        case "systemGray3":
            self = .systemGray3
        case "systemGray4":
            self = .systemGray4
        case "systemGray5":
            self = .systemGray5
        case "systemGray6":
            self = .systemGray6
        case "systemRed":
            self = .systemRed
        case "systemGreen":
            self = .systemGreen
        case "systemBlue":
            self = .systemBlue
        case "systemOrange":
            self = .systemOrange
        case "systemYellow":
            self = .systemYellow
        case "systemPink":
            self = .systemPink
        case "systemPurple":
            self = .systemPurple
        case "systemTeal":
            self = .systemTeal
        case "systemIndigo":
            self = .systemIndigo
        case "systemBrown":
            self = .systemBrown
        case "systemMint":
            self = .systemMint
        case "systemCyan":
            self = .systemCyan
        default:
            return nil
        }
    }
    
    case systemGray
    case systemGray2
    case systemGray3
    case systemGray4
    case systemGray5
    case systemGray6
    case systemRed
    case systemGreen
    case systemBlue
    case systemOrange
    case systemYellow
    case systemPink
    case systemPurple
    case systemTeal
    case systemIndigo
    case systemBrown
    case systemMint
    case systemCyan
    
    public var rawValue: String {
        switch self {
        case .systemGray:
            "systemGray"
        case .systemGray2:
            "systemGray2"
        case .systemGray3:
            "systemGray3"
        case .systemGray4:
            "systemGray4"
        case .systemGray5:
            "systemGray5"
        case .systemGray6:
            "systemGray6"
        case .systemRed:
            "systemRed"
        case .systemGreen:
            "systemGreen"
        case .systemBlue:
            "systemBlue"
        case .systemOrange:
            "systemOrange"
        case .systemYellow:
            "systemYellow"
        case .systemPink:
            "systemPink"
        case .systemPurple:
            "systemPurple"
        case .systemTeal:
            "systemTeal"
        case .systemIndigo:
            "systemIndigo"
        case .systemBrown:
            "systemBrown"
        case .systemMint:
            "systemMint"
        case .systemCyan:
            "systemCyan"
        }
    }
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
                return [ResolvedItem(id: jsonResponse.data.id, title: jsonResponse.data.name, subtitle: jsonResponse.data.address, category: jsonResponse.data.category, symbol: .pin, type: .appleResolved, coordinate: CLLocationCoordinate2D(latitude: jsonResponse.data.coordinates.lat, longitude: jsonResponse.data.coordinates.lon), systemColor: .systemRed, phone: jsonResponse.data.phone_number, website: url)]
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
                            systemColor: .systemBlue
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
                                systemColor: .systemRed
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
