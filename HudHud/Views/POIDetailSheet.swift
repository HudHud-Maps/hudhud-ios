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

// MARK: - POIDetailAction

enum POIDetailAction {
	case phone
	case website
	case moreInfo
}

// MARK: - POIDetailSheet

struct POIDetailSheet: View {

	let item: ResolvedItem
	let onStart: (Toursprung.RouteCalculationResult) -> Void
	let onMore: (POIDetailAction) -> Void

	@State var routes: Toursprung.RouteCalculationResult?

	@Environment(\.dismiss) var dismiss
	let onDismiss: () -> Void
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
							.lineLimit(2)
							.fixedSize(horizontal: false, vertical: true)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.bottom, 8)
					}

					Button(action: {
						self.dismiss()
						self.onDismiss()
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
								.lineLimit(1)
								.minimumScaleFactor(0.5)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					})
					.buttonStyle(.borderedProminent)
					.disabled(self.routes == nil)

					if let phone = self.item.phone, !phone.isEmpty {
						Button(action: {
							self.onMore(.phone)
						}, label: {
							VStack(spacing: 2) {
								Image(systemSymbol: .phoneFill)
								Text("Call", comment: "on poi detail sheet to call the poi")
									.lineLimit(1)
									.minimumScaleFactor(0.5)
							}
							.frame(maxWidth: .infinity)
							.padding(.vertical, 2)
						})
						.buttonStyle(.bordered)
					}
					if self.item.website != nil {
						Button(action: {
							self.onMore(.website)
						}, label: {
							VStack(spacing: 2) {
								Image(systemSymbol: .safariFill)
								Text("Web")
									.lineLimit(1)
									.minimumScaleFactor(0.5)
							}
							.frame(maxWidth: .infinity)
							.padding(.vertical, 2)
						})
						.buttonStyle(.bordered)
					}
					Button(action: {
						self.onMore(.moreInfo)
					}, label: {
						VStack(spacing: 2) {
							Image(systemSymbol: .ellipsisCircleFill)
							Text("More", comment: "on poi detail sheet to see more info")
								.lineLimit(1)
								.minimumScaleFactor(0.5)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					})
					.buttonStyle(.bordered)
				}
				.padding(.horizontal)

				AdditionalPOIDetailsView(routes: self.routes)
				DictionaryView(dictionary: self.item.userInfo)
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

				let results = try await Toursprung.shared.calculate(host: DebugStore().routingHost, options: options)
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
	let item = ResolvedItem.starbucks
	return POIDetailSheet(item: item) { _ in
		Logger.searchView.info("Start \(item)")
	} onMore: { _ in
		Logger.searchView.info("More \(item)")
	} onDismiss: {}
}
