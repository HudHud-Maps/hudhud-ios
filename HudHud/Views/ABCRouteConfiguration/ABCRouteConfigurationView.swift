//
//  ABCRouteConfigurationView.swift
//  HudHud
//
//  Created by Alaa . on 10/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import OSLog
import SFSafeSymbols
import SwiftUI

struct ABCRouteConfigurationView: View {

    // MARK: Properties

    @State var routeConfigurations: [ABCRouteConfigurationItem]
    @ObservedObject var mapViewStore: MapViewStore
    @ObservedObject var routingStore: RoutingStore

    // MARK: Content

    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(self.routeConfigurations, id: \.self) { route in
                        HStack {
                            route.icon
                                .font(.title3)
                                .foregroundColor(Color(.Colors.General._02Grey))
                                .frame(width: .leastNormalMagnitude)
                                .padding(.trailing, 12)
                                .anchorPreference(key: ItemBoundsKey.self, value: .bounds, transform: { anchor in
                                    [route.id: anchor]
                                })
                            Text(route.name)
                                .hudhudFont(.subheadline)
                                .foregroundColor(Color(.Colors.General._01Black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Spacer()
                            Image(systemSymbol: .line3Horizontal)
                                .foregroundColor(Color(.Colors.General._02Grey))
                        }
                        .padding(.leading, 5)
                    }
                    // List Adjustments
                    .onMove(perform: self.moveAction)
                    .onDelete { indexSet in
                        self.routeConfigurations.remove(atOffsets: indexSet)
                    }

                    .environment(\.defaultMinListRowHeight, 55)
                    .listRowBackground(Color(.quaternarySystemFill))
                }

                footer: {
                    Button {
                        self.mapViewStore.path.append(SheetSubView.navigationAddSearchView)
                    } label: {
                        HStack {
                            Image(systemSymbol: .plus)
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: .leastNormalMagnitude)
                                .padding(.trailing, 12)
                            Text("Add Location")
                                .hudhudFont(.subheadline)
                                .foregroundColor(Color(.Colors.General._07BlueMain))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                    .padding(.leading, 5)
                    .padding(.top, 14)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .overlayPreferenceValue(ItemBoundsKey.self) { bounds in
                GeometryReader { proxy in
                    let pairs = Array(zip(routeConfigurations, routeConfigurations.dropFirst()))

                    ForEach(pairs.dropLast(2), id: \.0.id) { item, next in
                        if let from = bounds[item.id], let to = bounds[next.id] {
                            Line(from: proxy[from][.bottom], to: proxy[to][.top])
                                .stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.5, 5], dashPhase: 4))
                                .foregroundColor(Color(.Colors.General._04GreyForLines))
                                .opacity(next == self.routeConfigurations.last ? 0 : 1) // Hide line for last row
                        }
                    }
                }
            }
            .onChange(of: self.routeConfigurations) { newRoute in
                Task {
                    do {
                        try await self.routingStore.navigate(to: newRoute)
                    } catch {
                        Logger.routing.error("Updating routes: \(error)")
                    }
                }
            }
        }
        // This line will update the routeConfigurations with latest waypoints after added stop point
        .onChange(of: self.routingStore.waypoints ?? []) { waypoints in
            self.routeConfigurations = waypoints
        }
    }

    // MARK: Functions

    // MARK: - Internal

    func moveAction(from source: IndexSet, to destination: Int) {
        self.routeConfigurations.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    ABCRouteConfigurationView(routeConfigurations: [
        .myLocation(Waypoint(coordinate: CLLocationCoordinate2D(latitude: 24.7192284, longitude: 46.6468331))),
        .waypoint(.coffeeAddressRiyadh),
        .waypoint(.theGarageRiyadh)
    ], mapViewStore: .storeSetUpForPreviewing, routingStore: .storeSetUpForPreviewing)
}
