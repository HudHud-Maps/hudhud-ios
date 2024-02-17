//
//  SearchResultItem.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SwiftUI
import MapKit

struct SearchResultItem: View {

	let prediction: Row

	var body: some View {
		HStack(alignment: .center, spacing: 12) {
			self.prediction.icon
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 24, height: 24)
				.foregroundStyle(.tertiary)
				.padding()
				.clipShape(Circle())
				.overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
				.layoutPriority(1)
				.frame(minWidth: .leastNonzeroMagnitude)

			VStack(alignment: .leading) {
				Text(self.prediction.title)
					.foregroundStyle(.primary)
					.font(.headline)
					.lineLimit(1)
				Text(self.prediction.subtitle)
					.foregroundStyle(.secondary)
					.font(.body)
					.lineLimit(1)
			}
			Spacer()
			Image(systemSymbol: .chevronRight)
				.foregroundStyle(.tertiary)
		}
		.padding(8)
	}
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	return SearchResultItem(prediction: .init(toursprung: .starbucks))
}
