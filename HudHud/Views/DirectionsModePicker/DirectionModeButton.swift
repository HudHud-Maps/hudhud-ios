//
//  DirectionModeButton.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct DirectionModeButton: ButtonStyle {
	@State var sfSymol: SFSymbol = .car
	func makeBody(configuration: Configuration) -> some View {
				VStack {
					Image(systemSymbol: sfSymol)
						.font(.title)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
					configuration.label
						.lineLimit(1)
						.minimumScaleFactor(0.5)
				}
				.frame(maxWidth: .infinity)
	}
}
