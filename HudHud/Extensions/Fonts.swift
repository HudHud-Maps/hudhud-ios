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

extension Font {
    static func hudhudFont(_ weight: FontWeight, size: CGFloat) -> Font {
        switch weight {
        case .bold:
            return .custom("PlusJakartaSans-Bold", size: size)
        case .boldItalic:
            return .custom("PlusJakartaSans-BoldItalic", size: size)
        case .extraBold:
            return .custom("PlusJakartaSans-ExtraBold", size: size)
        case .extraBoldItalic:
            return .custom("PlusJakartaSans-ExtraBoldItalic", size: size)
        case .extraLight:
            return .custom("PlusJakartaSans-ExtraLight", size: size)
        case .extraLightItalic:
            return .custom("PlusJakartaSans-ExtraLightItalic", size: size)
        case .italic:
            return .custom("PlusJakartaSans-Italic", size: size)
        case .light:
            return .custom("PlusJakartaSans-Light", size: size)
        case .lightItalic:
            return .custom("PlusJakartaSans-LightItalic", size: size)
        case .medium:
            return .custom("PlusJakartaSans-Medium", size: size)
        case .mediumItalic:
            return .custom("PlusJakartaSans-MediumItalic", size: size)
        case .regular:
            return .custom("PlusJakartaSans-Regular", size: size)
        case .semiBold:
            return .custom("PlusJakartaSans-SemiBold", size: size)
        case .semiBoldItalic:
            return .custom("PlusJakartaSans-SemiBoldItalic", size: size)
        }
    }
}

extension Text {
    func hudhudFont(_ fontWeight: FontWeight? = .regular, size: CGFloat? = nil) -> Text {
        return self.font(.hudhudFont(fontWeight ?? .regular, size: size ?? 16))
    }
}