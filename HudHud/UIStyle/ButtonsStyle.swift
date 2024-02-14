//
//  ButtonStyle.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct IconButton: ButtonStyle {
	let backgroundColor: Color?
	let foregroundColor: Color?

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding(7)
			.foregroundStyle(foregroundColor ?? .black)
			.bold()
			.background(backgroundColor)
			.clipShape(Capsule())
			.shadow(radius: 1)
	}
}
