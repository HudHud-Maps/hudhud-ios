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

	@ObservedObject var searchViewStore: SearchViewStore
	@ObservedObject var mapStore: MapStore
	@State var goPressed = false
	@State var searchShown: Bool = false

	var body: some View {
		VStack(spacing: 5) {
			HStack {
				Text("Directions", comment: "navigation sheet header")
					.font(.system(.title))
					.fontWeight(.semibold)
					.cornerRadius(10)
				Spacer()
				Button(action: {
					self.mapStore.routes = nil
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
			.padding(.top)

			if let route = self.mapStore.routes?.routes.first, let waypoints = self.mapStore.waypoints {
				ABCRouteConfigurationView(routeConfigurations: waypoints, mapStore: self.mapStore, searchViewStore: self.searchViewStore, searchShown: self.$searchShown)
				DirectionsSummaryView(
					directionPreviewData: DirectionPreviewData(
						duration: route.expectedTravelTime,
						distance: route.distance,
						typeOfRoute: "Fastest"
					), go: {
						self.goPressed.toggle()
					}
				)
				.padding(.bottom)
			}
		}
		.padding()
		.fullScreenCover(isPresented: self.$goPressed) {
			let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
			if let route = self.mapStore.routes?.routes.first {
				NavigationView(route: route, styleURL: styleURL)
			}
		}
		.sheet(isPresented: self.$searchShown) {
			// Initialize fresh instances of MapStore and SearchViewStore
			let freshMapStore = MapStore(motionViewModel: .shared)
			let freshSearchViewStore = SearchViewStore(mapStore: freshMapStore, mode: .live(provider: .toursprung))
			freshSearchViewStore.searchType = .addPOILocation
			return SearchSheet(mapStore: freshSearchViewStore.mapStore,
							   searchStore: freshSearchViewStore, onSearchCompletion: { item in
							   	self.searchViewStore.mapStore.waypoints?.append(item)
							   })
							   .frame(minWidth: 320)
							   .presentationCornerRadius(21)
							   .presentationDetents([.small, .medium, .large], selection: self.$searchViewStore.selectedDetent)
							   .presentationBackgroundInteraction(
							   	.enabled(upThrough: .large)
							   )
							   .interactiveDismissDisabled()
							   .ignoresSafeArea()
							   .presentationCompactAdaptation(.sheet)
		}
	}
}

#Preview {
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return NavigationSheetView(searchViewStore: searchViewStore, mapStore: searchViewStore.mapStore)
}
