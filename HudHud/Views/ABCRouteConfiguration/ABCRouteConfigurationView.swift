//
//  ABCRouteConfigurationView.swift
//  HudHud
//
//  Created by Alaa . on 10/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import OSLog
import POIService
import SFSafeSymbols
import SwiftLocation
import SwiftUI

struct ABCRouteConfigurationView: View {
	@State var routeConfigurations: [ABCRouteConfigurationItem]
	@ObservedObject var mapStore: MapStore
	@ObservedObject var searchViewStore: SearchViewStore
	@Binding var searchShown: Bool

	var body: some View {
		VStack {
			List {
				ForEach(self.routeConfigurations, id: \.self) { route in
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
				.onMove(perform: self.moveAction)
				.onDelete { indexSet in
					self.routeConfigurations.remove(atOffsets: indexSet)
				}
				.listRowBackground(Color(.quaternarySystemFill))
				// Add location button
				Button {
					self.searchViewStore.searchType = .returnPOILocation(completion: nil)
					self.searchShown = true
				} label: {
					HStack {
						Image(systemSymbol: .plus)
							.foregroundColor(.blue)
						Text("Add Location")
							.foregroundColor(.blue)
							.lineLimit(1)
							.minimumScaleFactor(0.5)
					}
				}
				.listRowBackground(Color(.systemBackground))
				.listRowSeparator(.hidden)
			}
			.listStyle(.grouped)
			.scrollContentBackground(.hidden)
			.scrollIndicators(.hidden)
			.overlayPreferenceValue(ItemBoundsKey.self) { bounds in
				GeometryReader { proxy in
					let pairs = Array(zip(routeConfigurations, routeConfigurations.dropFirst()))

					ForEach(pairs.dropLast(2), id: \.0.id) { item, next in
						if let from = bounds[item.id], let to = bounds[next.id] {
							Line(from: proxy[from][.bottom], to: proxy[to][.top])
								.stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.5, 5], dashPhase: 4))
								.foregroundColor(.secondary)
								.opacity(next == self.routeConfigurations.last ? 0 : 1) // Hide line for last row
						}
					}
				}
			}
			.onChange(of: self.routeConfigurations) { newRoute in
				var waypoints: [Waypoint] = []
				for item in newRoute {
					switch item {
					case let .myLocation(waypoint):
						waypoints.append(waypoint)
					case let .waypoint(point):
						let waypoint = Waypoint(coordinate: point.coordinate)
						waypoints.append(waypoint)
					}
				}
				self.mapStore.waypoints = newRoute
				self.updateRoutes(wayPoints: waypoints)
			}
		}
		// This line will update the routeConfigurations with latest waypoints after added stop point
		.onChange(of: self.mapStore.waypoints ?? []) { waypoints in
			self.routeConfigurations = waypoints
		}
	}

	// MARK: - Internal

	// Update routes by making a network request
	func updateRoutes(wayPoints: [Waypoint]) {
		Task {
			do {
				let options = NavigationRouteOptions(waypoints: wayPoints, profileIdentifier: .automobileAvoidingTraffic)
				options.shapeFormat = .polyline6
				options.distanceMeasurementSystem = .metric
				options.attributeOptions = []

				let results = try await Toursprung.shared.calculate(host: DebugStore().routingHost, options: options)
				self.mapStore.routes = results
			} catch {
				Logger.routing.error("Updating routes: \(error)")
			}
		}
	}

	func moveAction(from source: IndexSet, to destination: Int) {
		self.routeConfigurations.move(fromOffsets: source, toOffset: destination)
	}
}

#Preview {
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return ABCRouteConfigurationView(routeConfigurations: [
		.myLocation(Waypoint(coordinate: CLLocationCoordinate2D(latitude: 24.7192284, longitude: 46.6468331))),
		.waypoint(ResolvedItem(id: UUID().uuidString, title: "Coffee Address, Riyadh", subtitle: "Coffee Shop", type: .toursprung, coordinate: CLLocationCoordinate2D(latitude: 24.7076060, longitude: 46.6273354))),
		.waypoint(ResolvedItem(id: UUID().uuidString, title: "The Garage, Riyadh", subtitle: "Work", type: .toursprung, coordinate: CLLocationCoordinate2D(latitude: 24.7192284, longitude: 46.6468331)))
	], mapStore: searchViewStore.mapStore, searchViewStore: searchViewStore, searchShown: .constant(false))
}
