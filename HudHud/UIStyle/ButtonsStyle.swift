//
//  ButtonsStyle.swift
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

	// MARK: - Internal

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding(7)
			.foregroundStyle(self.foregroundColor ?? .black)
			.bold()
			.background(self.backgroundColor)
			.clipShape(Capsule())
			.shadow(radius: 1)
			.background(.thickMaterial, in: Capsule())
	}
}
