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
    @Binding var sheetSize: CGSize

    @State var routes: Toursprung.RouteCalculationResult?

    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void

    @EnvironmentObject var notificationQueue: NotificationQueue
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack {
                    if self.sheetSize.height < 200 {
                        Text(self.item.title)
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 150)
                    } else {
                        Text(self.item.title)
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
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
            .padding([.top, .leading, .trailing])
            .padding(.top)
            HStack {
                Button(action: {
                    guard let routes else { return }
                    self.onStart(routes)
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
                        // Perform phone action
                        if let phone = item.phone, let url = URL(string: "tel://\(phone)") {
                            self.openURL(url)
                        }
                        Logger.searchView.info("Item phone \(self.item.phone ?? "nil")")
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
                if let website = item.website {
                    Button(action: {
                        self.openURL(website)
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
                    Logger.searchView.info("more item \(self.item))")
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
                .fixedSize()
                .padding()
            DictionaryView(dictionary: self.item.userInfo)
            Spacer()
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
    @State var sheetSize: CGSize = .zero
    return POIDetailSheet(item: item, onStart: { _ in
        Logger.searchView.info("Start \(item)")
    }, sheetSize: $sheetSize, onDismiss: {})
}
