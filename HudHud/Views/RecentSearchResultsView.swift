//
//  RecentSearchResultsView.swift
//  HudHud
//
//  Created by Alaa . on 02/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapKit
import POIService
import SwiftUI

struct RecentSearchResultsView: View {
	let item: ResolvedItem
	let mapStore: MapStore
	let searchStore: SearchViewStore

	var body: some View {
		VStack {
			Button {
				let selectedItem = self.item
				let mapItems = [AnyDisplayableAsRow(self.item)]
				self.searchStore.selectedDetent = .medium
				self.mapStore.selectedItem = selectedItem
				self.mapStore.displayableItems = mapItems

			} label: {
				HStack(alignment: .center, spacing: 12) {
					self.item.icon
						.font(.title2)
						.aspectRatio(contentMode: .fit)
						.foregroundStyle(.white)
						.padding()
						.clipShape(Circle())
						.overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
						.layoutPriority(1)
						.frame(minWidth: .leastNonzeroMagnitude)
//						.background(
//							self.item.iconColor.mask(Circle())
//						)

					VStack(alignment: .leading) {
						Text(self.item.title)
							.foregroundStyle(.primary)
							.font(.headline)
							.lineLimit(1)
							.foregroundColor(.primary)
						Text(self.item.subtitle)
							.foregroundStyle(.secondary)
							.font(.body)
							.lineLimit(1)
							.foregroundColor(.primary)
					}
					Spacer()
				}
			}
			.padding(8)
		}
	}

}

#Preview {
	RecentSearchResultsView(item: .init(id: UUID().uuidString, title: "Riyadh", subtitle: "City Center", type: .toursprung, coordinate: .riyadh),
							mapStore: .storeSetUpForPreviewing,
							searchStore: .init(mapStore: .storeSetUpForPreviewing, mode: .preview))
}
