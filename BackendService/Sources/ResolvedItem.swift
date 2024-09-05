//
//  ResolvedItem.swift
//  BackendService
//
//  Created by Patrick Kladek on 05.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import SFSafeSymbols
import SwiftUI

// MARK: - ResolvedItem

public struct ResolvedItem: DisplayableAsRow, Codable, Hashable, CustomStringConvertible {

    // MARK: Nested Types

    public struct Coordinates: Codable, Equatable {
        var latitude: CLLocationDegrees
        var longitude: CLLocationDegrees
    }

    // MARK: Properties

    public var id: String
    public var title: String
    public var subtitle: String
    public var symbol: SFSymbol
    public var systemColor: SystemColor
    public var category: String?
    public let type: PredictionResult
    public var phone: String?
    public var website: URL?
    public var rating: Double?
    public var ratingsCount: Int?
    public var isOpen: Bool?
    public var trendingImage: String?
    public var mediaURLs: [URL]
    public let distance: Double?

    private var _coordinate: Coordinates

    // MARK: Computed Properties

    public var description: String {
        return "\(self.title), \(self.subtitle), coordinate: \(self.coordinate)"
    }

    public var color: Color {
        self.systemColor.swiftUIColor
    }

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self._coordinate.latitude, longitude: self._coordinate.longitude)
    }

    // MARK: Lifecycle

    public init(id: String, title: String, subtitle: String, category: String? = nil, symbol: SFSymbol = .pin, type: PredictionResult, coordinate: CLLocationCoordinate2D, color: SystemColor = .systemRed, phone: String? = nil, website: URL? = nil, rating: Double? = nil, ratingsCount: Int? = nil, isOpen: Bool? = nil, trendingImage: String? = nil, mediaURLs: [URL] = [], distance: Double? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.symbol = symbol
        self.type = type
        self._coordinate = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.phone = phone
        self.website = website
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.isOpen = isOpen
        self.trendingImage = trendingImage
        self.mediaURLs = mediaURLs
        self.systemColor = color
        self.distance = distance
    }

    // MARK: Functions

    // MARK: - Public

    public func resolve(in _: ApplePOI, baseURL _: String) async throws -> [AnyDisplayableAsRow] {
        return [AnyDisplayableAsRow(self)]
    }

    public func resolve(in _: HudHudPOI, baseURL _: String) async throws -> [AnyDisplayableAsRow] {
        return [AnyDisplayableAsRow(self)]
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.title)
        hasher.combine(self.subtitle)
    }
}

public extension ResolvedItem {

    static let ketchup = ResolvedItem(id: UUID().uuidString,
                                      title: "Ketch up",
                                      subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
                                      category: "Restaurant",
                                      type: .hudhud,
                                      coordinate: CLLocationCoordinate2D(latitude: 24.723583614203136, longitude: 46.633232873031076),
                                      phone: "0503539560",
                                      website: URL(string: "https://hudhud.sa"),
                                      rating: 4,
                                      ratingsCount: 56,
                                      mediaURLs: .previewMediaURLs)

    static let starbucks = ResolvedItem(id: UUID().uuidString,
                                        title: "Starbucks",
                                        subtitle: "The Beach",
                                        type: .hudhud,
                                        coordinate: CLLocationCoordinate2D(latitude: 24.732211928084162, longitude: 46.87863163915118),
                                        phone: "0503539560",
                                        website: URL(string: "https://hudhud.sa"),
                                        mediaURLs: .previewMediaURLs)

    static let publicPlace = ResolvedItem(id: UUID().uuidString,
                                          title: "publicPlace",
                                          subtitle: "Garden - Alyasmen - Riyadh",
                                          type: .hudhud,
                                          coordinate: CLLocationCoordinate2D(latitude: 24.595375923107532, longitude: 46.598253176098346),
                                          mediaURLs: .previewMediaURLs)

    static let artwork = ResolvedItem(id: UUID().uuidString,
                                      title: "Artwork",
                                      subtitle: "artwork - Al-Olya - Riyadh",
                                      type: .hudhud,
                                      coordinate: CLLocationCoordinate2D(latitude: 24.77888564128478, longitude: 46.61555160031425),
                                      phone: "0503539560",
                                      website: URL(string: "https://hudhud.sa"),
                                      mediaURLs: .previewMediaURLs)

    static let pharmacy = ResolvedItem(id: UUID().uuidString,
                                       title: "Pharmacy",
                                       subtitle: "Al-Olya - Riyadh",
                                       type: .hudhud,
                                       coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                                       phone: "0503539560",
                                       website: URL(string: "https://hudhud.sa"),
                                       mediaURLs: .previewMediaURLs)

    static let supermarket = ResolvedItem(id: UUID().uuidString,
                                          title: "Supermarket",
                                          subtitle: "Al-Narjs - Riyadh",
                                          type: .hudhud,
                                          coordinate: CLLocationCoordinate2D(latitude: 24.79671388339593, longitude: 46.70810150540095),
                                          phone: "0503539560",
                                          website: URL(string: "https://hudhud.sa"),
                                          mediaURLs: .previewMediaURLs)

    static let coffeeAddressRiyadh = ResolvedItem(id: UUID().uuidString,
                                                  title: "Coffee Address, Riyadh",
                                                  subtitle: "Coffee Shop",
                                                  type: .hudhud,
                                                  coordinate: CLLocationCoordinate2D(latitude: 24.7076060, longitude: 46.6273354))

    static let theGarageRiyadh = ResolvedItem(id: UUID().uuidString,
                                              title: "The Garage, Riyadh",
                                              subtitle: "Work",
                                              type: .hudhud,
                                              coordinate: CLLocationCoordinate2D(latitude: 24.7192284, longitude: 46.6468331))
}

public extension [URL] {
    static let previewMediaURLs: Self = [
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!,
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://img.freepik.com/free-photo/seafood-sushi-dish-with-details-simple-black-background_23-2151349421.jpg?t=st=1720950213~exp=1720953813~hmac=f62de410f692c7d4b775f8314723f42038aab9b54498e588739272b9879b4895&w=826")!,
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://img.freepik.com/free-photo/side-view-pide-with-ground-meat-cheese-hot-green-pepper-tomato-board_141793-5054.jpg?w=1380&t=st=1708506625~exp=1708507225~hmac=58a53cfdbb7f984c47750f046cbc91e3f90facb67e662c8da4974fe876338cb3")!
    ]
}
