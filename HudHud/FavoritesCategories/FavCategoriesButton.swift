//
//  FavCategoriesButton.swift
//  HudHud
//
//  Created by Alaa . on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct FavCategoriesButton: ButtonStyle {
	let sfSymbol: String?
	let tintColor: Color?
	@State private var wordHeight: CGFloat = 35
	func makeBody(configuration: Configuration) -> some View {
		VStack {
			Circle()
				.foregroundColor(.white)
				.shadow(color: .black.opacity(0.15), radius: 10, y: 10)
				.overlay {
					Image(systemSymbol: SFSymbol(rawValue: sfSymbol ?? "house.fill"))
						.resizable()
						.scaledToFit()
						.foregroundColor(tintColor)
						.padding(15)
				}
			configuration.label
				.tint(.primary)
				.font(.system(.subheadline))
				.lineLimit(1)
				.minimumScaleFactor(0.3)
				.baselineOffset(1)
				.background(GeometryReader {
					Color.clear.preference(key: SizePreferenceKey.self, value: $0.size.height)
				})
				.frame(maxHeight: wordHeight)
		}
			.onPreferenceChange(SizePreferenceKey.self, perform: { wordHeight = $0 })
	}
			private struct SizePreferenceKey: PreferenceKey {
					static var defaultValue: CGFloat = .zero
					static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
						value = min(value, nextValue())
				}
		}
}
