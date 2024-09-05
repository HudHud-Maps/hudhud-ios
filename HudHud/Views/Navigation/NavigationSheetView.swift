//
//  NavigationSheetView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import SwiftUI

struct NavigationSheetView: View {

    // MARK: Properties

    @ObservedObject var routingStore: RoutingStore
    @ObservedObject var mapViewStore: MapViewStore

    @Environment(\.dismiss) private var dismiss

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                Text("Directions", comment: "navigation sheet header")
                    .font(.title.bold())
                    .cornerRadius(10)
                Spacer()
                Button(action: {
                    self.routingStore.endTrip()
                    self.dismiss()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(.quinary.opacity(0.5))
                            .frame(width: 30, height: 30)

                        Image(.closeIcon)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                    .contentShape(Circle())
                })
                .tint(.secondary)
                .accessibilityLabel(Text("Close", comment: "accesibility label instead of x"))
            }
            .frame(height: 20)
            .padding(.horizontal)
            .padding(.top, 30)
            if let route = self.routingStore.potentialRoute?.routes.first, let waypoints = self.routingStore.waypoints {
                ABCRouteConfigurationView(routeConfigurations: waypoints, mapViewStore: self.mapViewStore, routingStore: self.routingStore)
                DirectionsSummaryView(
                    directionPreviewData: DirectionPreviewData(
                        duration: route.expectedTravelTime,
                        distance: route.distance,
                        typeOfRoute: "Fastest"
                    ), go: {
                        self.routingStore.navigate(to: route)
                    }
                )
                .padding([.horizontal, .bottom])
            }
        }
        .fullScreenCover(item: self.$routingStore.navigatingRouteFerrostar) { route in

            FerrostarNavigationView(waypoints: route.routeOptions.waypoints.dropFirst().map { waypoint in
                CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)
            })
        }
    }
}

#Preview {
    NavigationSheetView(routingStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing)
}
