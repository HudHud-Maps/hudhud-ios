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
}
