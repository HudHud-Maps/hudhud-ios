//
//  RecentSearchResults.swift
//  HudHud
//
//  Created by Alaa . on 02/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SwiftUI

struct RecentSearchResults: View {
	@State var poiArray = [POI]()

	var body: some View {
		VStack {
			ForEach(self.poiArray) { item in
				HStack(alignment: .center, spacing: 12) {
					item.icon
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
							item.iconColor.mask(Circle())
						)

					VStack(alignment: .leading) {
						Text(item.title)
							.foregroundStyle(.primary)
							.font(.headline)
							.lineLimit(1)
						Text(item.subtitle)
							.foregroundStyle(.secondary)
							.font(.body)
							.lineLimit(1)
					}
					Spacer()
					Button(action: {
//						self.searchViewStore.searchText = item.title
					}, label: {
						Image(systemSymbol: .chevronRight)
					})
					.padding(.trailing)
					.foregroundStyle(.tertiary)
				}
				.padding(8)
			}
		}
		.onAppear {
			// Retrieve POIs
			if let dataArray = UserDefaults.standard.array(forKey: "selectedItems") as? [Data] {
				do {
					let decoder = JSONDecoder()

					for data in dataArray {
						let poi = try decoder.decode(POI.self, from: data)

						self.poiArray.append(poi)
					}

				} catch {
					print("Error decoding data: \(error)")
				}
			} else {
				print("No data found in UserDefaults")
			}
		}
	}
}

#Preview {
	RecentSearchResults()
}
