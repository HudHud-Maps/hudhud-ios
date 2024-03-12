//
//  ABCRouteConfigurationView.swift
//  HudHud
//
//  Created by Alaa . on 10/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols
import POIService
import CoreLocation

struct ABCRouteConfigurationView: View {
	@State var routeConfigurations: [ABCRouteConfigurationItem]
	var body: some View {
		VStack {
			List {
				ForEach(routeConfigurations, id: \.self) { route in
					HStack {
						route.icon
						.font(.title3)
						.frame(width: .leastNormalMagnitude)
						.padding(.horizontal, 8)
						.anchorPreference(key: ItemBoundsKey.self, value: .bounds, transform: { anchor in
							[route.id: anchor]
						})
							Text(route.name)
								.foregroundColor(.primary)
								.lineLimit(1)
								.minimumScaleFactor(0.5)
							Spacer()
							Image(systemSymbol: .line3Horizontal)
					}
					.foregroundColor(.secondary)
				}
				// List Adjustments
				.onMove(perform: moveAction)
				.onDelete { indexSet in
					routeConfigurations.remove(atOffsets: indexSet)
				}
				.listRowBackground(Color(.quaternarySystemFill))
				// Add location button
				Button {
					routeConfigurations.append(.poi(POI(id: .random(in: 0 ... 1_000_000), title: "New Location", subtitle: "h", locationCoordinate: CLLocationCoordinate2D(latitude: 24.7189756, longitude: 46.6468911), type: "h")))
				} label: { //(24.7189756, 46.6468911)
					HStack {
						Image(systemSymbol: .plus)
							.foregroundColor(.secondary)
						Text("Add Location")
							.foregroundColor(.primary)
							.lineLimit(1)
							.minimumScaleFactor(0.5)
					}
				}
				.listRowBackground(Color(.quaternarySystemFill))
			}
			.overlayPreferenceValue(ItemBoundsKey.self, { bounds in
				GeometryReader{ proxy in
					let pairs = Array(zip(routeConfigurations, routeConfigurations.dropFirst()))
					ForEach(pairs, id: \.0.id) { (item , next) in
						if let from = bounds[item.id], let to = bounds[next.id] {
							Line(from: proxy[from][.bottom], to: proxy[to][.top])
								.stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.5, 5], dashPhase: 4))
								.foregroundColor(.secondary)
						}
					}
				}
			})
		}
	}
	func moveAction(from source: IndexSet, to destination: Int) {
		routeConfigurations.move(fromOffsets: source, toOffset: destination)
	}
}

#Preview {
	ABCRouteConfigurationView(routeConfigurations: [
		.myLocation,
		.poi(POI(title: "Coffee Address, Riyadh", subtitle: "Coffee Shop", locationCoordinate: CLLocationCoordinate2D(latitude: 24.7076060, longitude: 46.6273354), type: "Coffee")),
		.poi(POI(title: "The Garage, Riyadh", subtitle: "Work", locationCoordinate: CLLocationCoordinate2D(latitude: 24.7192284, longitude: 46.6468331), type: "Office"))
	])
}

