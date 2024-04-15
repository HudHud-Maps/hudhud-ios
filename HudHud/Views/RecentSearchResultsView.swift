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
	let poi: POI
	let mapStore: MapStore
	let searchStore: SearchViewStore

	var body: some View {
		VStack {
			Button {
				let selectedItem = self.poi
				let mapItems = [Row]()
				self.searchStore.selectedDetent = .medium
				self.mapStore.selectedItem = selectedItem
				self.mapStore.mapItems = mapItems

			} label: {
				HStack(alignment: .center, spacing: 12) {
					self.poi.icon
						.font(.title2)
						.foregroundStyle(.white)
						.padding()
						.clipShape(Circle())
						.overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
						.layoutPriority(1)
						.frame(minWidth: .leastNonzeroMagnitude)
						.background(
							self.poi.iconColor.mask(Circle())
						)

					VStack(alignment: .leading) {
						Text(self.poi.title)
							.foregroundStyle(.primary)
							.font(.headline)
							.lineLimit(1)
							.foregroundColor(.primary)
						Text(self.poi.subtitle)
							.foregroundStyle(.secondary)
							.font(.body)
							.lineLimit(1)
							.foregroundColor(.primary)
					}
				}
				Spacer()

				Image(systemSymbol: .chevronRight)

						.padding(.trailing)
						.foregroundStyle(.tertiary)
			}
			.padding(8)
		}
	}

}

// #Preview {
//	RecentSearchResultsView()
// }
