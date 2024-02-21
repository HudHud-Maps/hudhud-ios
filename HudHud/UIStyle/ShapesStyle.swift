//
//  ShapesStyle.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI
struct CircleShape: View {
	var body: some View {
		Circle()
			.fill(.secondary)
			.opacity(0.3)
			.frame(width: 3, height: 3)
	}
}
