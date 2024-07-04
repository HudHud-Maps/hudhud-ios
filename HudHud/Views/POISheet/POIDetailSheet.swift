//
//  POIDetailSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import OSLog
import SFSafeSymbols
import SimpleToast
import SwiftLocation
import SwiftUI

// MARK: - POIDetailSheet

struct POIDetailSheet: View {

    let item: ResolvedItem
    let onStart: (Toursprung.RouteCalculationResult) -> Void

    @State var routes: Toursprung.RouteCalculationResult?

    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void

    @EnvironmentObject var notificationQueue: NotificationQueue
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack {
                        Text(self.item.title)
                            .font(.title.bold())
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let category = self.item.category {
                            Text(category)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 8)
                        }
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
                .padding([.top, .leading, .trailing], 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: {
                            guard let routes else { return }
                            self.onStart(routes)
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Directions", icon: .arrowRightCircleFill, backgroundColor: .blue, fontColor: .white))
                            .disabled(self.routes == nil)

                        if let phone = self.item.phone, !phone.isEmpty {
                            Button(action: {
                                // Perform phone action
                                if let phone = item.phone, let url = URL(string: "tel://\(phone)") {
                                    self.openURL(url)
                                }
                                Logger.searchView.info("Item phone \(self.item.phone ?? "nil")")
                            }, label: {})
                                .buttonStyle(POISheetButtonStyle(title: "Call", icon: .phoneFill))
                        }
                        if let website = item.website {
                            Button(action: {
                                self.openURL(website)
                            }, label: {})
                                .buttonStyle(POISheetButtonStyle(title: "Web Site", icon: .websiteFill))
                        }
                        // order, save, Review, Media, Report
                        Button(action: {
                            Logger.searchView.info("order")
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Order", icon: .restaurant))
                        Button(action: {
                            Logger.searchView.info("save")
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Save", icon: .heartFill))
                        Button(action: {
                            Logger.searchView.info("review")
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Review", icon: .starSolid))
                        Button(action: {
                            Logger.searchView.info("media")
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Media", icon: .photoSolid))
                        Button(action: {
                            Logger.searchView.info("report")
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Report", icon: .reportSolid))
                    }
                    .padding(15)
                }
                .padding(.vertical, -15)
                VStack {
                    AdditionalPOIDetailsView(routes: self.routes)
                        .fixedSize()
                    DictionaryView(dictionary: self.item.userInfo)
                }
                .padding(.leading, 20)
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
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.selectedItem = ResolvedItem.starbucks
    return ContentView(searchStore: searchViewStore)
}
