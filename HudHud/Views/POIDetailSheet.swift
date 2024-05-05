//
//  POIDetailSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import OSLog
import POIService
import SFSafeSymbols
import SimpleToast
import SwiftLocation
import SwiftUI

struct POIDetailSheet: View {

	let item: ResolvedItem
	let onStart: (Toursprung.RouteCalculationResult) -> Void
	let onMore: () -> Void

	@State var routes: Toursprung.RouteCalculationResult?

	@Environment(\.dismiss) var dismiss
	@EnvironmentObject var notificationQueue: NotificationQueue

	var body: some View {
		NavigationStack {
			VStack(alignment: .leading) {
				HStack(alignment: .top) {
					VStack {
						Text(self.item.title)
							.font(.title.bold())
							.frame(maxWidth: .infinity, alignment: .leading)

						Text(self.item.subtitle)
							.font(.footnote)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.bottom, 8)
					}

					Button(action: {
						self.dismiss()
					}, label: {
						ZStack {
							Circle()
								.fill(.quaternary)
								.frame(width: 30, height: 30)

							Image(systemSymbol: .xmark)
								.font(.system(size: 15, weight: .bold, design: .rounded))
								.foregroundColor(.white)
						}
						.padding(8)
						.contentShape(Circle())
					})
					.buttonStyle(PlainButtonStyle())
					.accessibilityLabel(Text("Close", comment: "accesibility label instead of x"))
				}
				.padding([.top, .leading, .trailing])

				HStack {
					Button(action: {
						guard let routes else { return }
						self.onStart(routes)
						self.dismiss()

					}, label: {
						VStack(spacing: 2) {
							Image(systemSymbol: .carFill)
							Text("Start", comment: "get the navigation route")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					})
					.buttonStyle(.borderedProminent)
					.disabled(self.routes == nil)

					Button(action: self.onMore) {
						VStack(spacing: 2) {
							Image(systemSymbol: .phoneFill)
							Text("Call", comment: "on poi detail sheet to call the poi")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.bordered)

					Button(action: self.onMore) {
						VStack(spacing: 2) {
							Image(systemSymbol: .safariFill)
							Text("Web")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.bordered)

					Button(action: self.onMore) {
						VStack(spacing: 2) {
							Image(systemSymbol: .phoneFill)
							Text("More", comment: "on poi detail sheet to see more info")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.bordered)
				}
				.padding(.horizontal)

				Spacer()
//				DictionaryView(dictionary: self.poi.userInfo)
			}
		}
		.task {
			do {
				_ = try await Location.forSingleRequestUsage.requestPermission(.whenInUse)
				guard let userLocation = try await Location.forSingleRequestUsage.requestLocation().location else {
					return
				}
				let mapItem = self.item
				let locationCoordinate = mapItem.coordinate
				let waypoint1 = Waypoint(location: userLocation)
				let waypoint2 = Waypoint(coordinate: locationCoordinate)

				let waypoints = [
					waypoint1,
					waypoint2
				]

				let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
				options.shapeFormat = .polyline6
				options.distanceMeasurementSystem = .metric
				options.attributeOptions = []

				let results = try await Toursprung.shared.calculate(options)
				self.routes = results
			} catch {
				let notification = Notification(error: error)
				self.notificationQueue.add(notification: notification)
			}
		}
	}
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	let item = ResolvedItem(element: .starbucksKualaLumpur)! // swiftlint:disable:this force_unwrapping
	return POIDetailSheet(item: item) { _ in
		Logger.searchView.info("Start \(item)")
	} onMore: {
		Logger.searchView.info("More \(item)")
	}
}
