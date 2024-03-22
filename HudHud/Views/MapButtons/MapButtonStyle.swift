//
//  MapButtonStyle.swift
//  HudHud
//
//  Created by Alaa . on 21/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

struct MapButtonStyle: ButtonStyle {

	@State var mapButtonData: MapButtonData

	// MARK: - Internal

	func makeBody(configuration _: Configuration) -> some View {
		VStack {
			if case let .icon(symbol) = mapButtonData.sfSymbol {
				Image(systemSymbol: symbol)
					.font(.title2)
					.padding(10)
					.foregroundColor(.gray)
			} else if case let .text(text) = mapButtonData.sfSymbol {
				Text(text)
					.font(.title3)
					.padding(10)
					.foregroundColor(.gray)
			}
		}
		.background(Color.white)
		.cornerRadius(15)
		.shadow(color: .black.opacity(0.1), radius: 10, y: 4)
		.fixedSize()
	}
}
