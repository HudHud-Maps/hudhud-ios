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

    @State var viewMore: Bool = false

    private var shouldShowButton: Bool {
        let maxCharacters = 30
        return self.item.subtitle.count > maxCharacters
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(spacing: 0.0) {
                        Text(self.item.title)
                            .font(.title.bold())
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let category = self.item.category {
                            Text(category)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 4)
                        }
                        HStack {
                            Text(self.item.subtitle)
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                                .lineLimit(self.viewMore ? 3 : 1)
                            if self.shouldShowButton {
                                Button(self.viewMore ? "Read Less" : "Read More") {
                                    self.viewMore.toggle()
                                }
                                .font(.footnote)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                    }
                    Button(action: {
                        self.dismiss()
                        self.onDismiss()
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
                .padding([.top, .leading, .trailing], 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4.0) {
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
                    AdditionalPOIDetailsView(item: self.item, routes: self.routes)
                        .fixedSize()
                        .padding([.top, .trailing])
                    DictionaryView(dictionary: self.item.userInfo)
                    POIMediaView(item: self.item)
                        .padding(.leading)
                }
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
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                    return
                }

                let notification = Notification(error: error)
                self.notificationQueue.add(notification: notification)
            }
        }
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    let mediaURLs = [MediaURLs(type: "image", url: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77"),
                     MediaURLs(type: "image", url: "https://img.freepik.com/free-photo/seafood-sushi-dish-with-details-simple-black-background_23-2151349421.jpg?t=st=1720950213~exp=1720953813~hmac=f62de410f692c7d4b775f8314723f42038aab9b54498e588739272b9879b4895&w=826"),
                     MediaURLs(type: "image", url: "https://img.freepik.com/free-photo/side-view-pide-with-ground-meat-cheese-hot-green-pepper-tomato-board_141793-5054.jpg?w=1380&t=st=1708506625~exp=1708507225~hmac=58a53cfdbb7f984c47750f046cbc91e3f90facb67e662c8da4974fe876338cb3")]
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.selectedItem = ResolvedItem(id: UUID().uuidString, title: "Nozomi", subtitle: "7448 King Fahad Rd, Al Olaya, 4255, Riyadh 12331", category: "Restaurant", type: .toursprung, coordinate: CLLocationCoordinate2D(latitude: 24.732211928084162, longitude: 46.87863163915118), rating: 4.4, ratingsCount: 230, isOpen: true, mediaURLs: mediaURLs)
    return ContentView(searchStore: searchViewStore)
}
