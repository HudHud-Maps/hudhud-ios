//
//  SearchResultItem.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import POIService

struct SearchResultItem: View {

	let poi: POI

	var body: some View {
		HStack(alignment: .center, spacing: 12) {
			self.poi.icon
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
				Text(self.poi.name)
					.foregroundStyle(.primary)
					.font(.headline)
					.lineLimit(1)
				Text(self.poi.subtitle)
					.foregroundStyle(.secondary)
					.font(.body)
					.lineLimit(1)
			}
			Spacer()
			Image(systemName: "chevron.right")
				.foregroundStyle(.tertiary)
		}
		.padding(8)
	}
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	let poi = POI(element: .starbucksKualaLumpur)
	return SearchResultItem(poi: poi)
}
