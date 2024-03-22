//
//  MapButtonsView.swift
//  HudHud
//
//  Created by Alaa . on 03/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import OSLog
import SwiftUI

struct MapButtonsView: View {
	@State var mapButtonsData: [MapButtonData]

	var body: some View {
		VStack(spacing: 0) {
			ForEach(self.mapButtonsData.indices, id: \.self) { index in
				Button(action: self.mapButtonsData[index].action) {
					if case let .icon(symbol) = mapButtonsData[index].sfSymbol {
						Image(systemSymbol: symbol)
							.font(.title2)
							.padding(10)
							.foregroundColor(.gray)
					} else if case let .text(text) = mapButtonsData[index].sfSymbol {
						Text(text)
							.bold()
							.padding(10)
							.foregroundColor(.gray)
					}
				}
				if index != self.mapButtonsData.count - 1 {
					Divider()
				}
			}
		}
		.background(Color.white)
		.cornerRadius(15)
		.shadow(color: .black.opacity(0.1), radius: 10, y: 4)
		.fixedSize()
	}

	// MARK: - Private

	private func iconView(for style: MapButtonData.IconStyle) -> some View {
		switch style {
		case let .icon(symbol):
			return AnyView(Image(systemSymbol: symbol)) // Wrap Image in AnyView
		case let .text(text):
			return AnyView(Text(text)) // Wrap Text in AnyView
		}
	}
}

#Preview {
	MapButtonsView(mapButtonsData: [
		MapButtonData(sfSymbol: .icon(.map)) {
			print("Map button tapped")
		},
		MapButtonData(sfSymbol: .icon(.location)) {
			print("Location button tapped")
		},
		MapButtonData(sfSymbol: .icon(.cube)) {
			print("Location button tapped")
		}
	])
}
