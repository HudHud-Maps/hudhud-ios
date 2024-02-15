//
//  SearchResultItem.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SwiftUI

struct SearchResultItem: View {

	let row: Row

	var body: some View {
		HStack(alignment: .center, spacing: 12) {
			self.row.icon
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
				Text(self.row.title)
					.foregroundStyle(.primary)
					.font(.headline)
					.lineLimit(1)
				Text(self.row.subtitle)
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
	let poi = POI(element: .starbucksKualaLumpur)!	// swiftlint:disable:this force_unwrapping
	let row = Row(toursprung: poi)
	return SearchResultItem(row: row)
}
