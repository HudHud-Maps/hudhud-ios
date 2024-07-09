//
//  SystemColor+SwiftUIColor.swift
//  HudHud
//
//  Created by Naif Alrashed on 09/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI
import UIKit

extension SystemColor {
    var color: Color {
        switch self {
        case .systemGray:
            Color(.systemGray)
        case .systemGray2:
            Color(.systemGray2)
        case .systemGray3:
            Color(.systemGray3)
        case .systemGray4:
            Color(.systemGray4)
        case .systemGray5:
            Color(.systemGray5)
        case .systemGray6:
            Color(.systemGray6)
        case .systemRed:
            Color(.systemRed)
        case .systemGreen:
            Color(.systemGreen)
        case .systemBlue:
            Color(.systemBlue)
        case .systemOrange:
            Color(.systemOrange)
        case .systemYellow:
            Color(.systemYellow)
        case .systemPink:
            Color(.systemPink)
        case .systemPurple:
            Color(.systemPurple)
        case .systemTeal:
            Color(.systemTeal)
        case .systemIndigo:
            Color(.systemIndigo)
        case .systemBrown:
            Color(.systemBrown)
        case .systemMint:
            Color(.systemMint)
        case .systemCyan:
            Color(.systemCyan)
        }
    }
}
