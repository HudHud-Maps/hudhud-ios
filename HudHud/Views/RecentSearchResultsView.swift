//
//  RecentSearchResultsView.swift
//  HudHud
//
//  Created by Alaa . on 02/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SwiftUI

struct RecentSearchResultsView: View {
	let poi: POI
	let mapStore: MapStore

	var body: some View {
		VStack {
			Button {
				print("Selected item: \(self.poi))")
				let selectedItem = self.poi
				let mapItems = [Row(toursprung: selectedItem)]
				let newMapItem = MapItemsStatus(selectedItem: selectedItem, mapItems: mapItems)
				self.mapStore.mapItemStatus = newMapItem
				print("Updated mapItemStatus: \(self.mapStore.mapItemStatus)")

				print("error")
			} label: {
				HStack(alignment: .center, spacing: 12) {
					self.poi.icon
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 24, height: 24)
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
				Button(action: {
					//
				}, label: {
					Image(systemSymbol: .chevronRight)
				})
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
