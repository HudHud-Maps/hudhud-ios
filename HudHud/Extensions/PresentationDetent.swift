//
//  PresentationDetent.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

extension PresentationDetent {
    static let small: PresentationDetent = .height(80)
    static let third: PresentationDetent = {
        let screenHeight = UIScreen.main.bounds.height
        switch screenHeight {
        case let height where height > 900:
            return .fraction(0.33) // For larger screens like iPhone 14 Pro Max
        case let height where height > 800:
            return .fraction(0.30) // For medium screens like iPhone 14 Plus
        case let height where height > 700:
            return .fraction(0.25) // For smaller screens like iPhone 13/14
        default:
            return .fraction(0.2) // For very small screens
        }
    }()
}
