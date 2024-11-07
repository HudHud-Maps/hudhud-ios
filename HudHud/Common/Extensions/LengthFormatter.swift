//
//  LengthFormatter.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

extension LengthFormatter {
    static let distance: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        return formatter
    }()
}
