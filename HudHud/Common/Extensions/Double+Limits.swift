//
//  Double+Limits.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

extension Double {

    func limit(lower _: Double = 0, upper: Double) -> Double {
        Double.minimum(Double.maximum(self, 0), upper)
    }

    func wrap(min minValue: Double, max maxValue: Double) -> Double {
        let range = maxValue - minValue
        var wrappedValue = (self - minValue).truncatingRemainder(dividingBy: range)
        if wrappedValue < 0 {
            wrappedValue += range
        }
        return wrappedValue + minValue
    }
}

extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }

    func toRadians() -> Self {
        return self * .pi / 180
    }
}

extension CGSize {

    static func square(_ length: CGFloat) -> CGSize {
        return CGSize(width: length, height: length)
    }
}
