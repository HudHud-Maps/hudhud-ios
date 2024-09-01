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
import SwiftUI

// MARK: - POIDetailSheet

struct POIDetailSheet: View {

    let item: ResolvedItem
    @ObservedObject var routingStore: RoutingStore
    let onStart: (RoutingService.RouteCalculationResult) -> Void

    @State var routes: RoutingService.RouteCalculationResult?

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
                            Text(self.item.subtitle)
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
                        .padding(.bottom, 4)
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
                            guard let routes else { return }
                            self.onStart(routes)
                        }, label: {})
                            .buttonStyle(POISheetButtonStyle(title: "Directions", icon: .arrowRightCircleFill, backgroundColor: .Colors.General._07BlueMain, fontColor: .white))
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
                        .padding([.top, .trailing, .leading])
                    POIMediaView(mediaURLs: self.item.mediaURLs)
                }
            }
        }
        .task {
            await self.calculateRoute(for: self.item)
        }
        .onChange(of: self.item) { newItem in
            Task {
                await self.calculateRoute(for: newItem)
            }
        }
    }

    private func calculateRoute(for item: ResolvedItem) async {
        Task {
            do {
                let routes = try await self.routingStore.calculateRoute(for: item)
                self.routes = routes
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
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.selectedItem = .artwork
    return ContentView(searchStore: searchViewStore, mapViewStore: .storeSetUpForPreviewing)
}
