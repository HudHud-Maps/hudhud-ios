//
//  HudHudTextStyle.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI
import TypographyKit

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

extension View {
    func hudhudFontStyle(_ style: HudHudTextStyle) -> some View {
        return self.typography(style: UIFont.TextStyle(rawValue: style.rawValue))
    }
}
