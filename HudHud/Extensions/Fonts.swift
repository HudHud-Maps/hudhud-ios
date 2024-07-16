//
//  Fonts.swift
//  HudHud
//
//  Created by Fatima Aljaber on 03/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - FontWeight

enum FontWeight {
    case bold
    case boldItalic
    case extraBold
    case extraBoldItalic
    case extraLight
    case extraLightItalic
    case italic
    case light
    case lightItalic
    case medium
    case mediumItalic
    case regular
    case semiBold
    case semiBoldItalic
}

// MARK: - Fonts

enum Fonts {
    static func getSize(for textStyle: Font.TextStyle) -> CGFloat {
        switch textStyle {
        case .largeTitle:
            return 34
        case .title:
            return 28
        case .title2:
            return 22
        case .title3:
            return 20
        case .headline, .body:
            return 17
        case .callout:
            return 16
        case .subheadline:
            return 15
        case .footnote:
            return 13
        case .caption:
            return 12
        case .caption2:
            return 11
        @unknown default:
            return 17
        }
    }

    static func getWeight(for textStyle: Font.TextStyle) -> FontWeight {
        switch textStyle {
        case .largeTitle:
            return .bold
        case .title:
            return .semiBold
        case .title2:
            return .medium
        case .title3:
            return .regular
        case .headline:
            return .semiBold
        case .subheadline:
            return .medium
        case .body:
            return .regular
        case .callout:
            return .regular
        case .footnote:
            return .regular
        case .caption:
            return .regular
        case .caption2:
            return .regular
        case .extraLargeTitle:
            return .bold
        case .extraLargeTitle2:
            return .semiBold
        @unknown default:
            return .regular
        }
    }
}

extension UIFont {
    static func hudhudFont(_ weight: FontWeight, size: CGFloat) -> UIFont {
        switch weight {
        case .bold:
            return UIFont(name: "PlusJakartaSans-Bold", size: size)!
        case .boldItalic:
            return UIFont(name: "PlusJakartaSans-BoldItalic", size: size)!
        case .extraBold:
            return UIFont(name: "PlusJakartaSans-ExtraBold", size: size)!
        case .extraBoldItalic:
            return UIFont(name: "PlusJakartaSans-ExtraBoldItalic", size: size)!
        case .extraLight:
            return UIFont(name: "PlusJakartaSans-ExtraLight", size: size)!
        case .extraLightItalic:
            return UIFont(name: "PlusJakartaSans-ExtraLightItalic", size: size)!
        case .italic:
            return UIFont(name: "PlusJakartaSans-Italic", size: size)!
        case .light:
            return UIFont(name: "PlusJakartaSans-Light", size: size)!
        case .lightItalic:
            return UIFont(name: "PlusJakartaSans-LightItalic", size: size)!
        case .medium:
            return UIFont(name: "PlusJakartaSans-Medium", size: size)!
        case .mediumItalic:
            return UIFont(name: "PlusJakartaSans-MediumItalic", size: size)!
        case .regular:
            return UIFont(name: "PlusJakartaSans-Regular", size: size)!
        case .semiBold:
            return UIFont(name: "PlusJakartaSans-SemiBold", size: size)!
        case .semiBoldItalic:
            return UIFont(name: "PlusJakartaSans-SemiBoldItalic", size: size)!
        }
    }

    static func hudhudFont(_ textStyle: Font.TextStyle = .body) -> UIFont {
        let size = Fonts.getSize(for: textStyle)
        let weight = Fonts.getWeight(for: textStyle)
        return self.hudhudFont(weight, size: size)
    }
}

extension Font {
    static func hudhudFont(_ weight: FontWeight, size: CGFloat) -> Font {
        return Font(UIFont.hudhudFont(weight, size: size))
    }
}

extension Text {
    func hudhudFont(size: CGFloat, fontWeight: FontWeight = .regular) -> Text {
        return self.font(.hudhudFont(fontWeight, size: size))
    }

    func hudhudFont(_ textStyle: Font.TextStyle = .body) -> Text {
        return self.font(.hudhudFont(Fonts.getWeight(for: textStyle), size: Fonts.getSize(for: textStyle)))
    }
}
