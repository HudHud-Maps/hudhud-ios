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

struct FavoritesItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String // change later to localized if you can
    let tintColor: Color
    var item: ResolvedItem?
    var description: String?
    var type: String

    enum CodingKeys: String, CodingKey {
        case id, title, tintColor, item, description, type
    }

    // MARK: - Lifecycle

    init(id: UUID, title: String, tintColor: Color, item: ResolvedItem? = nil, description: String? = nil, type: String) {
        self.id = id
        self.title = title
        self.tintColor = tintColor
        self.item = item
        self.description = description
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        let tintColorHex = try container.decode(String.self, forKey: .tintColor)
        self.tintColor = Color(hex: tintColorHex) ?? Color.gray
        self.item = try container.decodeIfPresent(ResolvedItem.self, forKey: .item)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.type = try container.decode(String.self, forKey: .type)
    }

    // MARK: - Internal

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.tintColor.hexString, forKey: .tintColor)
        try container.encodeIfPresent(self.item, forKey: .item)
        try container.encodeIfPresent(self.description, forKey: .description)
        try container.encode(self.type, forKey: .type)
    }
}

// MARK: - FavoritesResolvedItems

struct FavoritesResolvedItems: RawRepresentable {
    var favoritesItems: [FavoritesItem]

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(favoritesItems) else {
            return "[]"
        }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Lifecycle

    init(items: [FavoritesItem]) {
        self.favoritesItems = items
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([FavoritesItem].self, from: data) else {
            return nil
        }
        self.favoritesItems = result
    }

}

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension FavoritesItem {
    static var favoriteForPreview = FavoritesItem(id: UUID(), title: "School",
                                                  tintColor: .gray, item: .pharmacy, description: " ", type: "School")
    static var favoritesInit = [
        FavoritesItem(id: UUID(), title: "Home",
                      tintColor: .gray, type: Types.home),
        FavoritesItem(id: UUID(), title: "Work",
                      tintColor: .gray, type: Types.work),
        FavoritesItem(id: UUID(), title: "School",
                      tintColor: .gray, type: Types.school)
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
}
