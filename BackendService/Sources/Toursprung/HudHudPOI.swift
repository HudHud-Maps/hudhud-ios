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

// MARK: - OpenAPIClientError

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
    case internalServerError(String)
    case unprocessableContent(String)
    case badRequest(String)
    case unauthorized(String)
    case notFound(String)
    case gone(String)

}

// MARK: - POIResponse

public struct POIResponse {
    public let items: [DisplayableRow]
    public let hasCategory: Bool
}

// MARK: - DisplayableRow

public enum DisplayableRow: Hashable, Identifiable {
    case category(Category)
    case resolvedItem(ResolvedItem)
    case categoryItem(ResolvedItem)
    case predictionItem(PredictionItem)

    // MARK: Computed Properties

    public var resolvedItem: ResolvedItem? {
        switch self {
        case .category, .predictionItem:
            nil
        case let .resolvedItem(resolvedItem), let .categoryItem(resolvedItem):
            resolvedItem
        }
    }

    public var id: String {
        switch self {
        case let .category(category):
            category.name
        case let .resolvedItem(resolvedItem):
            resolvedItem.id
        case let .predictionItem(predictionItem):
            predictionItem.id
        case let .categoryItem(resolvedItem):
            resolvedItem.id
        }
    }

    private var type: PredictionResult? {
        switch self {
        case .category:
            nil
        case let .resolvedItem(resolvedItem):
            resolvedItem.type
        case let .predictionItem(predictionItem):
            predictionItem.type
        case let .categoryItem(resolvedItem):
            resolvedItem.type
        }
    }

    // MARK: Functions

    public func resolve(in provider: ApplePOI, baseURL: String) async throws -> [DisplayableRow] {
        guard case let .apple(completion) = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: completion, baseURL: baseURL)
        return resolved.map(DisplayableRow.resolvedItem)
    }

    public func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [DisplayableRow] {
        guard case .hudhud = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: self, baseURL: baseURL)
        return resolved.map(DisplayableRow.resolvedItem)
    }

}

// MARK: - Category

public struct Category: Hashable {

    // MARK: Properties

    public let name: String
    public let icon: SFSymbol
    public let systemColor: SystemColor

    // MARK: Computed Properties

    public var color: Color {
        self.systemColor.swiftUIColor
    }

    // MARK: Lifecycle

    init(name: String, icon: SFSymbol, color: SystemColor) {
        self.name = name
        self.icon = icon
        self.systemColor = color
    }
}

// MARK: - HudHudPOI

public struct HudHudPOI: POIServiceProtocol {

    // MARK: Nested Types

    public enum PriceRange: Int {
        case cheap = 1
        case medium = 2
        case pricy = 3
        case expensive = 4

        // MARK: Computed Properties

        public var displayValue: String {
            switch self {
            case .cheap:
                return "$"
            case .medium:
                return "$$"
            case .pricy:
                return "$$$"
            case .expensive:
                return "$$$$"
            }
        }

        var backendValue: Operations.listPois.Input.Query.price_rangePayload {
            switch self {
            case .cheap:
                return ._1
            case .medium:
                return ._2
            case .pricy:
                return ._3
            case .expensive:
                return ._4
            }
        }

    }

    public enum SortBy: String {
        case relevance = "Relevance"
        case distance = "Distance"

        // MARK: Computed Properties

        var backendValue: Operations.listPois.Input.Query.sort_byPayload {
            switch self {
            case .relevance:
                return .relevance
            case .distance:
                return .distance
            }
        }
    }

    // MARK: Static Properties

    public static var serviceName = "HudHud"

    // MARK: Computed Properties

    private var currentLanguage: String {
        Locale.preferredLanguages.first ?? "en-US"
    }

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func lookup(id: String, prediction _: Any, baseURL: String) async throws -> [ResolvedItem] {
        let response = try await Client.makeClient(using: baseURL).getPoi(path: .init(id: id), headers: .init(Accept_hyphen_Language: self.currentLanguage))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let url: URL? = if let websiteString = jsonResponse.data.value1.website {
                    URL(string: websiteString)
                } else {
                    nil
                }
                let mediaURLsList = jsonResponse.data.value1.media_urls?.compactMap { URL(string: $0.url) }
                return [ResolvedItem(id: jsonResponse.data.value1.id,
                                     title: jsonResponse.data.value1.name,
                                     subtitle: jsonResponse.data.value1.address,
                                     category: jsonResponse.data.value1.category,
                                     symbol: .pin,
                                     type: .appleResolved,
                                     coordinate: CLLocationCoordinate2D(latitude: jsonResponse.data.value1.coordinates.lat,
                                                                        longitude: jsonResponse.data.value1.coordinates.lon),
                                     phone: jsonResponse.data.value1.phone_number,
                                     website: url,
                                     rating: jsonResponse.data.value1.rating,
                                     ratingsCount: jsonResponse.data.value1.ratings_count,
                                     isOpen: jsonResponse.data.value1.is_open,
                                     mediaURLs: mediaURLsList ?? [])]
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
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

    public func predict(term: String, coordinates: CLLocationCoordinate2D?, baseURL: String) async throws -> POIResponse {
        try await Task.sleep(nanoseconds: 190 * NSEC_PER_MSEC)
        try Task.checkCancellation()

        let response = try await Client.makeClient(using: baseURL).getTypeahead(query: .init(query: term, lat: coordinates?.latitude, lon: coordinates?.longitude), headers: .init(Accept_hyphen_Language: self.currentLanguage))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                var hasCategory = false
                let items: [DisplayableRow] = jsonResponse.data.compactMap { somethingElse in
                    // we need to parse this symbol from the backend, and we cannot do it in a type safe way
                    let icon = SFSymbol(rawValue: somethingElse.ios_category_icon.name) // swiftlint:disable:this sf_symbol_init
                    switch somethingElse._type {
                    case .category:
                        hasCategory = true
                        return .category(Category(
                            name: somethingElse.name,
                            icon: icon,
                            color: SystemColor(color: somethingElse.ios_category_icon.color)
                        ))
                    case .poi:
                        if let id = somethingElse.id,
                           let subtitle = somethingElse.address,
                           let latitude = somethingElse.coordinates?.lat,
                           let longitude = somethingElse.coordinates?.lon {
                            return .resolvedItem(ResolvedItem(
                                id: id,
                                title: somethingElse.name,
                                subtitle: subtitle,
                                category: somethingElse.category,
                                symbol: icon,
                                type: .hudhud,
                                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                color: SystemColor(color: somethingElse.ios_category_icon.color)
                            ))
                        } else {
                            assertionFailure("should have all the data here")
                        }
                        return nil
                    }
                }
                return POIResponse(items: items, hasCategory: hasCategory)
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

    // list pois /p
    public func items(for category: String, enterSearch: Bool, topRated: Bool? = nil, priceRange: PriceRange? = nil, sortBy: SortBy? = nil, rating: Double? = nil, location: CLLocationCoordinate2D?, baseURL: String) async throws -> [ResolvedItem] {
        try await Task.sleep(nanoseconds: 190 * NSEC_PER_MSEC)
        try Task.checkCancellation()
        var query: Operations.listPois.Input.Query
        let sortBy = sortBy?.backendValue
        if enterSearch {
            query = Operations.listPois.Input.Query(sort_by: sortBy, price_range: priceRange?.backendValue, rating: rating, text: category, lat: location?.latitude, lon: location?.longitude, top_rated: topRated)
        } else {
            query = Operations.listPois.Input.Query(sort_by: sortBy, price_range: priceRange?.backendValue, rating: rating, category: category, lat: location?.latitude, lon: location?.longitude, top_rated: topRated)
        }

        let response = try await Client.makeClient(using: baseURL).listPois(
            query: query,
            headers: .init(Accept_hyphen_Language: self.currentLanguage)
        )

        switch response {
        case let .ok(success):
            let body = try success.body.json
            return body.data.map { item -> ResolvedItem in
                let caseInsensitiveCategory = item.category.lowercased()
                let resolvedPriceRange = PriceRange(rawValue: item.price_range ?? 0)

                return ResolvedItem(
                    id: item.id,
                    title: item.name,
                    subtitle: "",
                    category: item.category,
                    symbol: categorySymbol[caseInsensitiveCategory] ?? .pin,
                    type: .hudhud,
                    coordinate: .init(latitude: item.coordinates.lat, longitude: item.coordinates.lon),
                    color: categoryColor[caseInsensitiveCategory] ?? .systemRed,
                    phone: item.phone_number,
                    website: URL(string: item.website ?? ""),
                    rating: item.rating,
                    ratingsCount: item.ratings_count,
                    isOpen: item.is_open,
                    mediaURLs: item.media_urls?.compactMap { URL(string: $0.url) } ?? [],
                    distance: item.distance,
                    driveDuration: item.duration,
                    priceRange: resolvedPriceRange?.rawValue
                )
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        case let .badRequest(error):
            throw try HudHudClientError.badRequest(error.body.json.message.debugDescription)
        }
    }

    // MARK: - Public

    public func lookup(id: String, baseURL: String) async throws -> ResolvedItem? {
        try await self.lookup(id: id, prediction: (), baseURL: baseURL).first
    }
}

// MARK: - SystemColor

// swiftlint:enable init_usage

public enum SystemColor: String, Codable {
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

    // MARK: Computed Properties

    public var swiftUIColor: Color {
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

    // MARK: Lifecycle

    init(color: Components.Schemas.IOSCategoryIcon.colorPayload) {
        switch color {
        case .systemGray:
            self = .systemGray
        case .systemGray2:
            self = .systemGray2
        case .systemGray3:
            self = .systemGray3
        case .systemGray4:
            self = .systemGray4
        case .systemGray5:
            self = .systemGray5
        case .systemGray6:
            self = .systemGray6
        case .systemRed:
            self = .systemRed
        case .systemGreen:
            self = .systemGreen
        case .systemBlue:
            self = .systemBlue
        case .systemOrange:
            self = .systemOrange
        case .systemYellow:
            self = .systemYellow
        case .systemPink:
            self = .systemPink
        case .systemPurple:
            self = .systemPurple
        case .systemTeal:
            self = .systemTeal
        case .systemIndigo:
            self = .systemIndigo
        case .systemBrown:
            self = .systemBrown
        case .systemMint:
            self = .systemMint
        case .systemCyan:
            self = .systemCyan
        }
    }
}

// swiftlint:disable sf_symbol_init
let categorySymbol: [String: SFSymbol] = [
    "clinic": .crossCaseFill,
    "bank": .banknoteFill,
    "atm": .creditcardAnd123,
    "building": .building2Fill,
    "hospital": .crossFill,
    "movie Theater": .film,
    "gym": .dumbbellFill,
    "coffee Shop": .cupAndSaucerFill,
    "restaurant": .forkKnife,
    "clothing Store": .tshirtFill,
    "office": .buildingColumnsFill,
    "company": .buildingFill,
    "book store": .booksVerticalFill,
    "hotel": .bedDoubleFill,
    "shop": .cartFill
]
let categoryColor: [String: SystemColor] = [
    "clinic": .systemPink,
    "bank": .systemIndigo,
    "atm": .systemIndigo,
    "building": .systemIndigo,
    "hospital": .systemPink,
    "movie Theater": .systemTeal,
    "gym": .systemPink,
    "coffee Shop": .systemOrange,
    "restaurant": .systemOrange,
    "clothing Store": .systemBlue,
    "office": .systemIndigo,
    "company": .systemIndigo,
    "book store": .systemGray,
    "hotel": .systemIndigo,
    "shop": .systemBlue
]
// swiftlint:enable sf_symbol_init
