//
//  ProviderButton.swift
//  HudHud
//
//  Created by Patrick Kladek on 19.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct ProviderButton: View {

	@ObservedObject var searchViewModel: SearchViewModel

	var body: some View {
		Button {
			switch searchViewModel.mode {
			case .live(let provider):
				self.searchViewModel.mode = .live(provider: provider.next())
			case .preview:
				self.searchViewModel.mode = .preview
			}
		} label: {
			switch self.searchViewModel.mode {
			case .live(.apple):
				Image(systemSymbol: .appleLogo)
			case .live(.toursprung):
				Text("MTK")
			case .preview:
				Text("Preview")
			}
		}
		.padding(12)
		.frame(minWidth: 44, minHeight: 44)
		.background {
			RoundedRectangle(cornerRadius: 10)
				.fill(Material.regular)
		}
	}
}

@available(iOS 17, *)
#Preview("Apple", traits: .sizeThatFitsLayout) {
	ProviderButton(searchViewModel: .init(mode: .live(provider: .apple)))
		.padding()
}

@available(iOS 17, *)
#Preview("Toursprung", traits: .sizeThatFitsLayout) {
	ProviderButton(searchViewModel: .init(mode: .live(provider: .toursprung)))
		.padding()
}
