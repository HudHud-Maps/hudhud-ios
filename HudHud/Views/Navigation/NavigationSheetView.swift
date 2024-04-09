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
	var route: Route?
	let location = Location()
	var dismissAction: () -> Void
	@State var goPressed = false

	var body: some View {
		VStack {
			HStack {
				Text("Direction")
					.font(.system(.title))
					.fontWeight(.semibold)
					.cornerRadius(10)
				Spacer()
				Button(action: {
					self.dismissAction()
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
				.accessibilityLabel(Text("Close"))
			}
			if let route = self.route {
				DirectionsSummaryView(
					directionPreviewData: DirectionPreviewData(
						duration: route.expectedTravelTime,
						distance: route.distance,
						typeOfRoute: "Fastest"
					), go: {
						self.goPressed.toggle()
					}
				)
			}
		}
		.padding()
		.fullScreenCover(isPresented: self.$goPressed) {
			let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
			if let route = self.route {
				NavigationView(route: route, styleURL: styleURL)
			}
		}
	}
}

#Preview {
	NavigationSheetView(dismissAction: {})
}
