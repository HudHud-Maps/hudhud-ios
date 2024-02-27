//
//  FavoriteCategoriesButton.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct FavoriteCategoriesButton: ButtonStyle {
	let sfSymbol: SFSymbol?
	let tintColor: Color?
	func makeBody(configuration: Configuration) -> some View {
		VStack {
			Image(systemSymbol: sfSymbol ?? .houseFill)
				.font(.title)
				.foregroundColor(tintColor)
				.padding(15)
				.background {
					Circle()
						.foregroundColor(.white)
						.shadow(color: .black.opacity(0.15), radius: 10, y: 10)
				}
			configuration.label
				.tint(.primary)
				.lineLimit(1)
				.minimumScaleFactor(0.5)
		}
	}
}
