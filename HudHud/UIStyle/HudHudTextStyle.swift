//
//  HudHudTextStyle.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - HudHudTextStyle

enum HudHudTextStyle: String {
    case headingXXLarge = "heading.xxLarge"
    case headingXLarge = "heading.xLarge"
    case headingLarge = "heading.large"
    case headingMedium = "heading.medium"
    case headingSmall = "heading.small"
    case headingXSmall = "heading.xSmall"
    case labelLarge = "label.large"
    case labelMedium = "label.medium"
    case labelSmall = "label.small"
    case labelSmallExtraBold = "label.smallExtraBold"
    case labelXSmall = "label.xSmall"
    case labelXXSmall = "label.xxSmall"
    case paragraphLarge = "paragraph.large"
    case paragraphMedium = "paragraph.medium"
    case paragraphSmall = "paragraph.small"
    case paragraphXSmall = "paragraph.xSmall"
}

// MARK: - Typography

struct Typography {

    // Function to get UIFont based on TextStyle
    func font(for style: HudHudTextStyle) -> UIFont {
        let fontName = "Plus Jakarta Sans"
        let (size, weight): (CGFloat, UIFont.Weight)

        switch style {
        case .headingXXLarge:
            size = 32; weight = .bold
        case .headingXLarge:
            size = 28; weight = .bold
        case .headingLarge:
            size = 24; weight = .bold
        case .headingMedium:
            size = 20; weight = .bold
        case .headingSmall, .labelLarge:
            size = 18; weight = .semibold
        case .headingXSmall, .labelMedium, .paragraphMedium:
            size = 16; weight = .semibold
        case .labelSmall, .labelSmallExtraBold:
            size = 14; weight = .semibold
        case .labelXSmall:
            size = 12; weight = .semibold
        case .labelXXSmall:
            size = 10; weight = .semibold
        case .paragraphLarge:
            size = 18; weight = .medium
        case .paragraphSmall:
            size = 14; weight = .medium
        case .paragraphXSmall:
            size = 12; weight = .medium
        }

        // Safely create and return the font
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont.withWeight(weight)
        } else {
            assertionFailure("Font not found, ensure it is packaged via the build pipeline")
            return .systemFont(ofSize: size)
        }
    }
}

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = self.fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: self.pointSize)
    }
}

extension Font {
    static func hudhudFontStyle(_ textStyle: HudHudTextStyle) -> Font {
        let typography = Typography()
        let uiFont = typography.font(for: textStyle)
        return Font(uiFont)
    }
}

extension View {
    func hudhudFontStyle(_ textStyle: HudHudTextStyle) -> some View {
        self.font(.hudhudFontStyle(textStyle))
    }
}
