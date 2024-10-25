//
//  POIDetailSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import FerrostarCoreFFI
import Foundation
import OSLog
import SFSafeSymbols
import SimpleToast
import SwiftUI

// MARK: - POIDetailSheet

struct POIDetailSheet: View {

    // MARK: Properties

    let item: ResolvedItem
    let didDenyLocationPermission: Bool
    let onStart: ([Route]?) -> Void
    let preplanRoutes: (ResolvedItem) -> Void
    let onDismiss: () -> Void

    @State var routes: [Route]?
    @State var viewMore: Bool = false
    @State var askToEnableLocation = false

    var navigationVisualization: NavigationVisualization

    @EnvironmentObject var notificationQueue: NotificationQueue

    var mapStore: MapStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: Computed Properties

    private var shouldShowButton: Bool {
        let maxCharacters = 30
        return (self.item.subtitle ?? self.item.coordinate.formatted()).count > maxCharacters
    }

    // MARK: Lifecycle

    init(
        mapStore: MapStore,
        item: ResolvedItem,
        navigationVisualization: NavigationVisualization,
        didDenyLocationPermission: Bool,
        onStart: @escaping ([Route]?) -> Void,
        preplanRoutes: @escaping (ResolvedItem) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.mapStore = mapStore
        self.item = item
        self.onStart = onStart
        self.onDismiss = onDismiss
        self.navigationVisualization = navigationVisualization
        self.preplanRoutes = preplanRoutes
        self.didDenyLocationPermission = didDenyLocationPermission
    }

    // MARK: Content

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(spacing: .zero) {
                    Text(self.item.title)
                        .hudhudFont(.title)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let category = self.item.category {
                        Text(category)
                            .hudhudFont(.footnote)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                    HStack {
                        Text(self.item.subtitle ?? self.item.coordinate.formatted())
                            .hudhudFont(.footnote)
                            .foregroundStyle(Color.Colors.General._01Black)
                            .multilineTextAlignment(.leading)
                            .lineLimit(self.viewMore ? 3 : 1)
                        if self.shouldShowButton {
                            Button(self.viewMore ? "Read Less" : "Read More") {
                                self.viewMore.toggle()
                            }
                            .font(.footnote)
                            .foregroundStyle(Color.Colors.General._07BlueMain)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(self.item.category != nil ? .bottom : .vertical, 4)
                }
                Button(action: {
                    self.dismiss()
                    self.onDismiss()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(Color.Colors.General._03LightGrey)
                            .frame(width: 30, height: 30)

                        Image(.closeIcon)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
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
                        if self.didDenyLocationPermission {
                            self.askToEnableLocation = true
                        } else {
                            self.onStart(self.routes)
                        }
                    }, label: {})
                        .buttonStyle(POISheetButtonStyle(title: "Directions", icon: .arrowRightCircleFill, backgroundColor: .Colors.General._07BlueMain, fontColor: .white))

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
                    .padding([.top, .trailing, .leading])
                POIMediaView(mediaURLs: self.item.mediaURLs)
            }
            Spacer()
        }
        .alert(
            "Location Needed",
            isPresented: self.$askToEnableLocation
        ) {
            Button("Enable location in permissions") {
                self.openURL(URL(string: UIApplication.openSettingsURLString)!) // swiftlint:disable:this force_unwrapping
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable your location to get directions")
        }
        .task {
            await self.calculateRoute(for: self.item)
        }
        .onChange(of: self.item) { _, newItem in
            Task {
                await self.calculateRoute(for: newItem)
            }
        }
    }
}

// MARK: - Private

private extension POIDetailSheet {

    func calculateRoute(for item: ResolvedItem) async {
        self.preplanRoutes(item)
    }
}

// MARK: - Preview

// #Preview(traits: .sizeThatFitsLayout) {
//    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
//    searchViewStore.mapStore.select(.artwork)
//    return ContentView(
//        store: .init(
//            mapStore: .storeSetUpForPreviewing,
//            sheetStore: .storeSetUpForPreviewing,
//            mapViewStore: .storeSetUpForPreviewing,
//            searchViewStore: searchViewStore,
//            userLocationStore: .storeSetUpForPreviewing,
//            navigationEngine: .init(),
//            mapContainerViewStore: MapViewContainerStore(
//                navigationVisualization: .init(
//                    navigationEngine: .init(),
//                    routePlanner: RoutePlanner(routingService: GraphHopperRouteProvider())
//                )
//            )
//        )
//    )
// }
