//
//  NavigationSheetView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import POIService
import SwiftLocation
import SwiftUI
import ToursprungPOI

struct NavigationSheetView: View {

	@ObservedObject var mapStore: MapStore
	@State var goPressed = false

	var body: some View {
		VStack {
			HStack {
				Text("Direction", comment: "navigation sheet header")
					.font(.system(.title))
					.fontWeight(.semibold)
					.cornerRadius(10)
				Spacer()
				Button(action: {
					self.mapStore.route = nil
					self.mapStore.waypoints = nil
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

			if let route = self.mapStore.route, let waypoints = self.mapStore.waypoints {
				DirectionsSummaryView(
					directionPreviewData: DirectionPreviewData(
						duration: route.expectedTravelTime,
						distance: route.distance,
						typeOfRoute: "Fastest"
					), go: {
						self.goPressed.toggle()
					}
				)
				ABCRouteConfigurationView(routeConfigurations: waypoints, mapStore: self.mapStore)
			}
		}
		.padding()
		.fullScreenCover(isPresented: self.$goPressed) {
			let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
			if let route = self.mapStore.route {
				NavigationView(route: route, styleURL: styleURL)
			}
		}
	}
}

#Preview {
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return NavigationSheetView(mapStore: searchViewStore.mapStore)
}
