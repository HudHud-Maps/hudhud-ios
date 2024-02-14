//
//  ButtonStyle.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct iconButton: ButtonStyle {
	var backgroundColor: Color = .red
	var foregroundColor: Color = .black

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding()
			.font(.system(size: 16))
			.foregroundStyle(backgroundColor)
			.background(.white)
			.clipShape(Capsule())
			.shadow(radius: 1)
		
	}
}
