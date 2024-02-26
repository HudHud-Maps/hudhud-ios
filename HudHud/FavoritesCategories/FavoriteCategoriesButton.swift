//
//  FavCategoriesButton.swift
//  HudHud
//
//  Created by Alaa . on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct FavoriteCategoriesButton: ButtonStyle {
	let sfSymbol: String?
	let tintColor: Color?
	func makeBody(configuration: Configuration) -> some View {
		VStack {
			Image(systemSymbol: SFSymbol(rawValue: sfSymbol ?? "house.fill"))
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
