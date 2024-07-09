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
import SwiftLocation
import SwiftUI

struct NavigationSheetView: View {

    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Directions", comment: "navigation sheet header")
                    .hudhudFont(.title)
                    .cornerRadius(10)
                Spacer()
                Button(action: {
                    self.mapStore.routes = nil
                    self.mapStore.waypoints = nil
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
            .padding(.top)

            if let route = self.mapStore.routes?.routes.first, let waypoints = self.mapStore.waypoints {
                ABCRouteConfigurationView(routeConfigurations: waypoints, mapStore: self.mapStore, searchViewStore: self.searchViewStore)
                DirectionsSummaryView(
                    directionPreviewData: DirectionPreviewData(
                        duration: route.expectedTravelTime,
                        distance: route.distance,
                        typeOfRoute: "Fastest"
                    ), go: {
                        if self.mapStore.navigatingRoute == nil {
                            self.mapStore.navigatingRoute = route
                        } else {
                            self.mapStore.navigatingRoute = nil
                        }
                    }
                )
                .padding(.bottom)
            }
        }
        .padding()
    }
}

#Preview {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing

    @StateObject var debugStore = DebugStore()

    return NavigationSheetView(searchViewStore: searchViewStore, mapStore: searchViewStore.mapStore, debugStore: debugStore)
}
