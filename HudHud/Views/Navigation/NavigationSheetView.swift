//
//  NavigationSheetView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import FerrostarCoreFFI
import SwiftUI

struct NavigationSheetView: View {

    // MARK: Properties

//    @ObservedObject var routingStore: RoutingStore
    @ObservedObject var sheetStore: SheetStore
    @ObservedObject var navigationVisualization: NavigationVisualization

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
                    self.navigationVisualization.clear()
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

            if let route = self.navigationVisualization.selectedRoute {
                let waypoints = self.navigationVisualization.waypoints
                ABCRouteConfigurationView(
                    routeConfigurations: waypoints,
                    sheetStore: self.sheetStore,
                    navigationVisualization: self.navigationVisualization
                )
                DirectionsSummaryView(
                    directionPreviewData: DirectionPreviewData(
                        duration: route.duration,
                        distance: route.distance,
                        typeOfRoute: "Fastest"
                    ), go: {
//                        self.routingStore.navigatingRoute = route
                        self.navigationVisualization.startNavigation()
                        self.sheetStore.reset()
                    }
                )
                .padding([.horizontal, .bottom])
            }
        }
    }
}

// #Preview {
//    NavigationSheetView(routingStore: .storeSetUpForPreviewing, sheetStore: .storeSetUpForPreviewing)
// }
