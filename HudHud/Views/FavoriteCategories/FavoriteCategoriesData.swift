//
//  FavoriteCategoriesData.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import POIService
import SFSafeSymbols
import SwiftUI

// MARK: - FavoriteCategoriesData

struct FavoriteCategoriesData: Identifiable, Codable, Equatable {
    let id: Int
    var title: String // change later to localized if you can
    let sfSymbol: SFSymbol
    let tintColor: Color
    var item: ResolvedItem?
    var description: String?
    var type: String

    enum CodingKeys: String, CodingKey {
        case id, title, sfSymbol, tintColor, item, description, type
    }

    // MARK: - Lifecycle

    init(id: Int, title: String, sfSymbol: SFSymbol, tintColor: Color, item: ResolvedItem? = nil, description: String? = nil, type: String) {
        self.id = id
        self.title = title
        self.sfSymbol = sfSymbol
        self.tintColor = tintColor
        self.item = item
        self.description = description
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.sfSymbol = try container.decode(SFSymbol.self, forKey: .sfSymbol)
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
        try container.encode(self.sfSymbol, forKey: .sfSymbol)
        try container.encode(self.tintColor.hexString, forKey: .tintColor)
        try container.encodeIfPresent(self.item, forKey: .item)
        try container.encodeIfPresent(self.description, forKey: .description)
        try container.encode(self.type, forKey: .type)
    }
}

// MARK: - FavoriteItems

struct FavoriteItems: RawRepresentable { // I hate this name
    var favoriteCategoriesData: [FavoriteCategoriesData]

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(favoriteCategoriesData),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }

    // MARK: - Lifecycle

    init(items: [FavoriteCategoriesData]) {
        self.favoriteCategoriesData = items
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([FavoriteCategoriesData].self, from: data) else {
            return nil
        }
        self.favoriteCategoriesData = result
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
