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
    let onDismiss: () -> Void

    let tabItems = ["Overview", "Reviews", "Photos", "Similar Places", "About"]
    @State var selectedTab = "Overview"
    @Namespace var animation
    @State var showTabView: Bool = false
  
    @State var routes: [RouteModel]?
    @State var viewMore: Bool = false
    @State var askToEnableLocation = false

    @ObservedObject var routingStore: RoutingStore

    @EnvironmentObject var notificationQueue: NotificationQueue

    let formatter = Formatters()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: Computed Properties

    private var shouldShowButton: Bool {
        let maxCharacters = 30
        return (self.item.subtitle ?? self.item.coordinate.formatted()).count > maxCharacters
    }

    private var currentWeekday: HudHudPOI.OpeningHours.WeekDay {
        let weekdayIndex = Calendar.current.component(.weekday, from: Date())
        return HudHudPOI.OpeningHours.WeekDay.allCases[weekdayIndex - 1]
    }

    // MARK: Lifecycle

    init(
        item: ResolvedItem,
        routingStore: RoutingStore,
        didDenyLocationPermission: Bool,
        onStart: @escaping ([Route]?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.item = item
        self.onStart = onStart
        self.onDismiss = onDismiss
        self.routingStore = routingStore
        self.didDenyLocationPermission = didDenyLocationPermission
    }

    // MARK: Content

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(self.item.title)
                        .hudhudFont(.title)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    self.categoryView
                    HStack {
                        self.ratingView
                        self.priceRangeView
                        self.accessibilityView
                    }
                    HStack {
                        self.openStatusView
                        self.routeInformationView
                    }
                }

                // Close Button
                Button {
                    self.dismiss()
                    self.onDismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.Colors.General._03LightGrey)
                            .frame(width: 30, height: 30)
                        Image(.closeIcon)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .padding(4)
                    .contentShape(Circle())
                }
                .tint(.secondary)
                .accessibilityLabel(Text("Close", comment: "Accessibility label instead of x"))
            }
            .padding([.top, .leading, .trailing], 20)

            if self.showTabView {
                self.tabView
                switch self.selectedTab {
                case "Overview":
                    Text("Overview")
                case "Reviews":
                    Text("Reviews")
                case "Photos":
                    POIMediaView(mediaURLs: self.item.mediaURLs)
                case "Similar Places":
                    Text("Similar Places")
                case "About":
                    Text("About")
                default:
                    Text("Select a Tab")
                }
            }
        }

        if !self.showTabView {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4.0) {
                    Button(action: {
                        if self.didDenyLocationPermission {
                            self.askToEnableLocation = true
                        } else {
                            self.onStart(self.routes?.map(\.route))
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

            POIMediaView(mediaURLs: self.item.mediaURLs)
        }
        Spacer()

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

    var tabView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack {
                    ForEach(self.tabItems, id: \.self) { tab in
                        VStack {
                            Text(tab)
                                .hudhudFont(.subheadline)
                                .fontWeight(self.selectedTab == tab ? .semibold : .regular)
                                .foregroundStyle(self.selectedTab == tab ? Color.Colors.General._06DarkGreen : Color.Colors.General._01Black)

                            if self.selectedTab == tab {
                                Capsule()
                                    .foregroundStyle(Color.Colors.General._06DarkGreen)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "filter", in: self.animation)
                            } else {
                                Capsule()
                                    .foregroundColor(Color(.clear))
                                    .frame(height: 3)
                            }
                        }
                        .padding(10)
                        .onTapGesture {
                            withAnimation(.easeOut) {
                                self.selectedTab = tab
                            }

                            // Scroll to the selected tab
                            withAnimation {
                                scrollProxy.scrollTo(tab, anchor: .center)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .overlay {
                Divider()
                    .offset(x: 0, y: 15)
            }
        }
    }

    private var categoryView: some View {
        Group {
            if let category = self.item.category {
                HStack {
                    Text(category)
                        .hudhudFont(.footnote)
                        .foregroundStyle(Color.Colors.General._02Grey)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subCategory = item.subCategory {
                        Text("•")
                            .hudhudFont(.footnote)
                            .foregroundStyle(Color.Colors.General._02Grey)
                        Text(subCategory)
                            .hudhudFont(.footnote)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var ratingView: some View {
        Group {
            if let rating = self.item.rating {
                HStack(spacing: 1) {
                    Text("\(rating, specifier: "%.1f")")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)

                    ForEach(1 ... 5, id: \.self) { index in
                        Image(systemSymbol: .starFill)
                            .font(.footnote)
                            .foregroundColor(index <= Int(rating.rounded()) ? .Colors.General._13Orange : .Colors.General._04GreyForLines)
                    }

                    Text("•")
                        .hudhudFont(.caption2)
                        .foregroundStyle(Color.Colors.General._02Grey)

                    Text("(\(self.item.ratingsCount ?? 0))")
                        .hudhudFont(.subheadline)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
            } else {
                Text("No ratings")
                    .hudhudFont(.caption)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
    }

    private var priceRangeView: some View {
        Group {
            if let priceRangeValue = self.item.priceRange,
               let priceRange = HudHudPOI.PriceRange(rawValue: priceRangeValue) {
                HStack {
                    Text("•")
                        .hudhudFont(.caption2)
                        .foregroundStyle(Color.Colors.General._02Grey)
                    Text(priceRange.displayValue)
                        .hudhudFont(.subheadline)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
            }
        }
    }

    private var accessibilityView: some View {
        Group {
            if let wheelchairAccessible = self.item.isWheelchairAccessible, wheelchairAccessible {
                HStack {
                    Text("•")
                        .hudhudFont(.caption2)
                        .foregroundStyle(Color.Colors.General._02Grey)
                    Image(systemSymbol: .figureRoll)
                        .hudhudFont(.subheadline)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
            }
        }
    }

    private var openStatusView: some View {
        Group {
            if let isOpen = self.item.isOpen,
               let openingHoursToday = self.item.openingHours?.first(where: { $0.day == currentWeekday }) {
                HStack {
                    Text("\(isOpen ? "Open" : "Closed") until \(self.nextAvailableTime(isOpen: isOpen, hours: openingHoursToday.hours))")
                        .hudhudFont(.subheadline)
                        .foregroundStyle(isOpen ? Color(.Colors.General._06DarkGreen) : Color(.Colors.General._12Red))
                }
            }
        }
    }

    private var routeInformationView: some View {
        Group {
            if let route = routes?.first {
                HStack {
                    Image(systemSymbol: .carFill)
                        .hudhudFont(.caption2)
                        .foregroundStyle(Color.Colors.General._02Grey)
                    Text("\(self.formatter.formatDuration(duration: route.route.duration)) (\(self.formatter.formatDistance(distance: route.route.distance)))")
                        .hudhudFont(.subheadline)
                        .foregroundStyle(Color.Colors.General._02Grey)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
    }

    private var openiningHoursView: some View {
        Group {
            if let openingHoursList = item.openingHours {
                ForEach(HudHudPOI.OpeningHours.WeekDay.allCases, id: \.self) { day in
                    HStack {
                        Text("\(day.displayValue)")
                            .font(.headline)

                        if let openingHoursForDay = openingHoursList.first(where: { $0.day == day }) {
                            Text(openingHoursForDay.hours.map(\.displayValue).joined(separator: ", "))
                                .font(.subheadline)
                        } else {
                            Text("Closed")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: Functions

    private func nextAvailableTime(isOpen: Bool, hours: [HudHudPOI.OpeningHours.TimeRange]) -> String {
        let nextTime = isOpen ? hours.last?.end : hours.first?.start
        if let nextHour = nextTime {
            return self.formatHour(nextHour)
        } else {
            return "Unknown"
        }
    }

    private func formatHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.timeZone = .current
            formatter.dateFormat = "h:mm a" // 12-hour format with minutes and AM/PM
            return formatter.string(from: date)
        } else {
            return "Invalid Time"
        }
    }

}

// MARK: - Private

private extension POIDetailSheet {

    func calculateRoute(for item: ResolvedItem) async {
        do {
            let routes = try await self.routingStore.calculateRoutes(for: item)
            self.routes = routes
            self.routingStore.routes = routes // TODO: Improve it
            self.routingStore.selectRoute(withId: routes.last?.id ?? 0)
        } catch let error as URLError {
            if error.code == .cancelled {
                // ignore cancelled errors
                return
            }
            // if the error is related to the user's internet connetion, display the error to the user
            let notification = Notification(error: error)
            self.notificationQueue.add(notification: notification)
        } catch {
            // we do not show an error in all other cases
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.select(.artwork)
    return ContentView(
        searchStore: searchViewStore,
        mapViewStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    )
}
