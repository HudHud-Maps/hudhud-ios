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
	let poiArray: [POI]
	var onSelect: (POI) -> Void

	var body: some View {
		VStack {
			ForEach(self.poiArray) { item in
				Button {
					self.onSelect(item)
				} label: {
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
								.foregroundColor(.primary)
							Text(item.subtitle)
								.foregroundStyle(.secondary)
								.font(.body)
								.lineLimit(1)
								.foregroundColor(.primary)
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
	}

}

// #Preview {
//	RecentSearchResultsView()
// }
