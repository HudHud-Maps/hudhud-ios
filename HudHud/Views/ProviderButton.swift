//
//  ProviderButton.swift
//  HudHud
//
//  Created by Patrick Kladek on 19.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import OSLog
import SwiftUI

struct ProviderButton: View {

	@ObservedObject var searchViewStore: SearchViewStore

	var body: some View {
		Button {
			switch self.searchViewStore.mode {
			case let .live(provider):
				self.searchViewStore.mode = .live(provider: provider.next())
				Logger.searchView.info("Map Mode live")
			case .preview:
				self.searchViewStore.mode = .live(provider: .toursprung)
				Logger.searchView.info("Map Mode toursprung")
			}
		} label: {
			switch self.searchViewStore.mode {
			case .live(.apple):
				Image(systemSymbol: .appleLogo)
			case .live(.toursprung):
				Text("MTK")
			case .preview:
				Image(systemSymbol: .pCircle)
			}
		}
		.frame(minWidth: 44, minHeight: 44)
		.background {
			RoundedRectangle(cornerRadius: 10)
				.fill(Material.thickMaterial)
		}
	}
}

@available(iOS 17, *)
#Preview("Apple", traits: .sizeThatFitsLayout) {
	ProviderButton(searchViewStore: .init(mode: .live(provider: .apple)))
		.padding()
}

@available(iOS 17, *)
#Preview("Toursprung", traits: .sizeThatFitsLayout) {
	ProviderButton(searchViewStore: .init(mode: .live(provider: .toursprung)))
		.padding()
}
