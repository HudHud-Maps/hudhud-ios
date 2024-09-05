//
//  PredictionItem.swift
//  BackendService
//
//  Created by Patrick Kladek on 05.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - PredictionItem

public struct PredictionItem: DisplayableAsRow, Hashable {

    // MARK: Properties

    public var id: String
    public var title: String
    public var subtitle: String
    public var symbol: SFSymbol
    public var type: PredictionResult

    // MARK: Computed Properties

    public var tintColor: Color {
        .red
    }

    // MARK: Lifecycle

    public init(id: String, title: String, subtitle: String, symbol: SFSymbol = .pin, type: PredictionResult) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.type = type
    }

    // MARK: Static Functions

    // MARK: - Public

    public static func == (lhs: PredictionItem, rhs: PredictionItem) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: Functions

    public func resolve(in provider: ApplePOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        guard case let .apple(completion) = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: completion, baseURL: baseURL)
        let mapped = resolved.map {
            AnyDisplayableAsRow($0)
        }
        return mapped
    }

    public func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        guard case .hudhud = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: self, baseURL: baseURL)

        let mapped = resolved.map {
            AnyDisplayableAsRow($0)
        }
        return mapped
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.title)
        hasher.combine(self.subtitle)
    }

}

public extension PredictionItem {

    static let ketchup = PredictionItem(id: UUID().uuidString,
                                        title: "Ketch up",
                                        subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
                                        symbol: .pin,
                                        type: .appleResolved)
    static let starbucks = PredictionItem(id: UUID().uuidString,
                                          title: "Starbucks",
                                          subtitle: "The Beach",
                                          symbol: .pin,
                                          type: .appleResolved)
    static let publicPlace = PredictionItem(id: UUID().uuidString,
                                            title: "publicPlace",
                                            subtitle: "Garden - Alyasmen - Riyadh",
                                            symbol: .pin,
                                            type: .appleResolved)
    static let artwork = PredictionItem(id: UUID().uuidString,
                                        title: "Artwork",
                                        subtitle: "artwork - Al-Olya - Riyadh",
                                        symbol: .pin,
                                        type: .appleResolved)
    static let pharmacy = PredictionItem(id: UUID().uuidString,
                                         title: "Pharmacy",
                                         subtitle: "Al-Olya - Riyadh",
                                         symbol: .pin,
                                         type: .appleResolved)
    static let supermarket = PredictionItem(id: UUID().uuidString,
                                            title: "Supermarket",
                                            subtitle: "Al-Narjs - Riyadh",
                                            symbol: .pin,
                                            type: .appleResolved)
}
