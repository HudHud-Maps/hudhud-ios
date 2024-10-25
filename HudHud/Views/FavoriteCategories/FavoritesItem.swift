//
//  FavoritesItem.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import SFSafeSymbols
import SwiftUI

// MARK: - FavoritesItem

struct FavoritesItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String // change later to localized if you can
    let tintColor: TintColor
    var item: ResolvedItem?
    var description: String?
    var type: String
}

// MARK: - FavoritesResolvedItems

struct FavoritesResolvedItems: RawRepresentable {

    // MARK: Properties

    var favoritesItems: [FavoritesItem]

    // MARK: Computed Properties

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(favoritesItems),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return result
    }

    // MARK: Lifecycle

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([FavoritesItem].self, from: data) else {
            return nil
        }
        self.favoritesItems = result
    }

    init(items: [FavoritesItem]) {
        self.favoritesItems = items
    }

}

extension FavoritesItem {
    static var favoriteForPreview = FavoritesItem(id: UUID(), title: "School",
                                                  tintColor: TintColor.entertainmentLeisure, item: .pharmacy, description: " ", type: "School")
    static var favoritesInit = [
        FavoritesItem(id: UUID(), title: "Home",
                      tintColor: TintColor.personalShopping, type: Types.home),
        FavoritesItem(id: UUID(), title: "Work",
                      tintColor: TintColor.personalShopping, type: Types.work),
        FavoritesItem(id: UUID(), title: "School",
                      tintColor: TintColor.entertainmentLeisure, type: Types.school)
    ]
}

extension FavoritesItem {
    enum Types {
        static var home = "Home"
        static var work = "Work"
        static var school = "School"
    }

    func getSymbol(type: String) -> SFSymbol {
        switch type {
        case "Home":
            return .houseFill
        case "Work":
            return .bagFill
        case "School":
            return .buildingColumnsFill
        default:
            return .heartFill
        }
    }

    enum TintColor: Codable {
        case personalShopping
        case entertainmentLeisure

        // MARK: Computed Properties

        public var POI: Color {
            switch self {
            case .personalShopping:
                Color.Colors.POI._01PersonalShopping
            case .entertainmentLeisure:
                Color.Colors.POI._07EntertainmentLeisure
            }
        }
    }

}
