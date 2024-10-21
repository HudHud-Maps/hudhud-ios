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
    static let third: PresentationDetent = .fraction(0.33)
    static let nearHalf: PresentationDetent = .height(UIScreen.main.bounds.height / 2.5)
}
