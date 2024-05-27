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

struct NavigationSheetView: View {

    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var mapStore: MapStore
    @State var goPressed = false

    @ObservedObject var debugStore: DebugStore

    @State var searchShown: Bool = false

    @Environment(\.dismiss) private var dismiss

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
                NavigationView(route: route, styleURL: styleURL, debugSettings: self.debugStore)
            }
        }
        .sheet(isPresented: self.$searchShown) {
            // Initialize fresh instances of MapStore and SearchViewStore
            let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
            let freshSearchViewStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchViewStore.mode)
            freshSearchViewStore.searchType = .returnPOILocation(completion: { item in
                self.searchViewStore.mapStore.waypoints?.append(item)
            })
            return SearchSheet(mapStore: freshSearchViewStore.mapStore,
                               searchStore: freshSearchViewStore)
                .frame(minWidth: 320)
                .presentationCornerRadius(21)
                .interactiveDismissDisabled()
                .ignoresSafeArea()
                .presentationCompactAdaptation(.sheet)
        }
    }
}

#Preview {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing

    @StateObject var debugStore = DebugStore()

    return NavigationSheetView(searchViewStore: searchViewStore, mapStore: searchViewStore.mapStore, debugStore: debugStore)
}
