//
//  UIColor.swift
//  HudHud
//
//  Created by patrick on 16.07.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {

    func hex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#000000"
        }

        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
}
