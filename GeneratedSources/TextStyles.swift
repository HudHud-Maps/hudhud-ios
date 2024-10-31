// NOTE: Do not edit this auto generataed file. It will be recreated on every build
//swiftlint:disable:all

import Foundation
import SwiftUI
import TypographyKit

// MARK: - HudHudTextStyle

enum HudHudTextStyle: String { 
    
    case headingLarge = "heading.large"
    
    case headingMedium = "heading.medium"
    
    case headingSmall = "heading.small"
    
    case headingXlarge = "heading.xLarge"
    
    case headingXsmall = "heading.xSmall"
    
    case headingXxlarge = "heading.xxLarge"
    
    case labelLarge = "label.large"
    
    case labelMedium = "label.medium"
    
    case labelSmall = "label.small"
    
    case labelSmallextrabold = "label.smallExtraBold"
    
    case labelXsmall = "label.xSmall"
    
    case labelXxsmall = "label.xxSmall"
    
    case paragraphLarge = "paragraph.large"
    
    case paragraphMedium = "paragraph.medium"
    
    case paragraphSmall = "paragraph.small"
    
    case paragraphXsmall = "paragraph.xSmall"
    
}

extension View {
    func hudhudFontStyle(_ style: HudHudTextStyle) -> some View {
        return self.typography(style: UIFont.TextStyle(rawValue: style.rawValue))
    }
}

//swiftlint:enable:all