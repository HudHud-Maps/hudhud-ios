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

    // MARK: Nested Types

    private enum POISheetViewMetrics {
        static let compactSheetHeight: CGFloat = UIScreen.main.bounds.height / 6 // 1/6 of the screen height
        static let expandedSheetHeight: CGFloat = UIScreen.main.bounds.height / 4 // 1/4 of the screen height
    }

    // MARK: Properties

    @State var pointOfInterestStore: PointOfInterestStore
    let sheetStore: SheetStore
    @ObservedObject var favoritesStore: FavoritesStore
    let didDenyLocationPermission: Bool
    let onStart: ([Route]?) -> Void
    let onDismiss: () -> Void

    @State var selectedTab: POIOverviewView.Tab = .overview
    @Namespace var animation
    @State var showTabView: Bool = true
    @State var routes: [Route]?
    @State var viewMore: Bool = false
    @State var askToEnableLocation = false
    @ObservedObject var routingStore: RoutingStore
    @EnvironmentObject var notificationQueue: NotificationQueue

    let formatter = Formatters()

    @State private var selectedMedia: URL?
    @State private var cameraStore = CameraStore()
    @State private var photoStore = PhotoStore()
    private let displayPlaceholderReviews = true // we are waiting for the backend to implement reviews

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: Computed Properties

    private var shouldShowButton: Bool {
        let maxCharacters = 30
        return (self.pointOfInterestStore.pointOfInterest.subtitle ?? self.pointOfInterestStore.pointOfInterest.coordinate.formatted())
            .count > maxCharacters
    }

    private var currentWeekday: HudHudPOI.OpeningHours.WeekDay {
        let weekdayIndex = Calendar.current.component(.weekday, from: Date())
        return HudHudPOI.OpeningHours.WeekDay.allCases[weekdayIndex - 1]
    }

    // MARK: Lifecycle

    init(pointOfInterestStore: PointOfInterestStore,
         sheetStore: SheetStore,
         favoritesStore: FavoritesStore,
         routingStore: RoutingStore,
         didDenyLocationPermission: Bool,
         onStart: @escaping ([Route]?) -> Void,
         onDismiss: @escaping () -> Void) {
        self.pointOfInterestStore = pointOfInterestStore
        self.sheetStore = sheetStore
        self.onStart = onStart
        self.onDismiss = onDismiss
        self.routingStore = routingStore
        self.didDenyLocationPermission = didDenyLocationPermission
        self.favoritesStore = favoritesStore
    }

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(self.pointOfInterestStore.pointOfInterest.title)
                        .hudhudFont(.title)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(self.sheetStore.sheetHeight < 220 ? 1 : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if self.pointOfInterestStore.pointOfInterest.title == "Dropped Pin" {
                        HStack {
                            Text(self.pointOfInterestStore.pointOfInterest.coordinate.formatted())
                                .hudhudFont(.subheadline)
                                .foregroundStyle(Color.Colors.General._02Grey)
                                .lineLimit(1)
                            Text(" · ")
                                .hudhudFont(.subheadline)
                                .foregroundStyle(Color.Colors.General._02Grey)
                            self.routeInformationView
                        }
                        .padding(.vertical, 5)
                    }
                    self.categoryView
                    if self.sheetStore.sheetHeight >= POISheetViewMetrics.compactSheetHeight {
                        HStack(spacing: 0.0) {
                            self.ratingView
                            self.priceRangeView
                            self.accessibilityView
                        }
                        HStack(spacing: 0.0) {
                            self.openStatusView
                                .padding(.vertical, 7)
                            self.routeInformationView
                                .padding(.vertical, 7)
                        }
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
                        Image(systemSymbol: .xmark)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.Colors.General._01Black)
                    }
                    .padding(4)
                    .contentShape(Circle())
                }
                .tint(.secondary)
                .accessibilityLabel(Text("Close", comment: "Accessibility label instead of x"))
            }
            .padding([.top, .leading, .trailing], 15)

            if self.sheetStore.sheetHeight > POISheetViewMetrics.expandedSheetHeight {
                self.tabView
                ScrollView {
                    VStack {
                        // Switch between views based on the selected tab
                        switch self.selectedTab {
                        case .overview:
                            // Show all content in the Overview tab
                            POIOverviewView(poiData: POISheetStore(item: self.pointOfInterestStore.pointOfInterest),
                                            selectedTab: self.$selectedTab)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.Colors.General._05WhiteBackground)
                                .cornerRadius(14)

                            if let rating = self.pointOfInterestStore.pointOfInterest.rating {
                                RatingSectionView(store: RatingStore(staticRating: rating,
                                                                     ratingsCount: self.pointOfInterestStore.pointOfInterest.ratingsCount ?? 0,
                                                                     interactiveRating: 0))
                                    .padding(.vertical)
                                    .background(Color.Colors.General._05WhiteBackground)
                                    .cornerRadius(14)
                            }

                            if self.displayPlaceholderReviews {
                                ReviewsListView(reviews: Review.listOfReviewsForPreview)
                                    .padding(.vertical)
                                    .background(Color.Colors.General._05WhiteBackground)
                                    .cornerRadius(14)
                            }

                            PhotoSectionView(item: self.pointOfInterestStore.pointOfInterest, selectedTab: self.$selectedTab,
                                             photoStore: self.photoStore, cameraStore: self.cameraStore)
                                .background(Color.Colors.General._05WhiteBackground)
                                .cornerRadius(14)

                        case .photos:
                            PhotoTabView(item: self.pointOfInterestStore.pointOfInterest, selectedMedia: self.$selectedMedia)
                                .padding(-10)

                        case .review:
                            if let rating = self.pointOfInterestStore.pointOfInterest.rating {
                                RatingSectionView(store: RatingStore(staticRating: rating,
                                                                     ratingsCount: self.pointOfInterestStore.pointOfInterest.ratingsCount ?? 0,
                                                                     interactiveRating: 0))
                                    .padding(.vertical)
                                    .background(Color.Colors.General._05WhiteBackground)
                                    .cornerRadius(14)
                            }

                            if self.displayPlaceholderReviews {
                                ReviewsListView(reviews: Review.listOfReviewsForPreview)
                                    .padding(.vertical)
                                    .background(Color.Colors.General._05WhiteBackground)
                                    .cornerRadius(14)
                            }

                        case .about:
                            POIOverviewView(poiData: POISheetStore(item: self.pointOfInterestStore.pointOfInterest),
                                            selectedTab: self.$selectedTab)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.Colors.General._05WhiteBackground)
                                .cornerRadius(14)

                        case .similar:
                            Text("Similar")
                        }
                    }
                    .padding(10)
                }
                .padding(.bottom, 80)
                .scrollIndicators(.hidden)
                .background(Color.Colors.General._03LightGrey)
                .overlay(alignment: .bottomTrailing) {
                    if self.selectedTab == .photos {
                        Button(action: {
                            self.cameraStore.showAddPhotoConfirmation = true
                        }, label: {
                            ZStack {
                                Circle()
                                    .fill(Color.Colors.General._06DarkGreen)
                                    .frame(width: 56, height: 56)
                                Image(.addPhoto)
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color.Colors.General._05WhiteBackground)
                            }
                        })
                        .padding(.bottom, 100)
                        .padding(.trailing, 16)
                    }
                }
                .sheet(item: self.$selectedMedia) { mediaURL in
                    FullPageImage(mediaURL: mediaURL,
                                  mediaURLs: self.pointOfInterestStore.pointOfInterest.mediaURLs)
                }
            }
            Spacer()
        }
        .addPhotoConfirmationDialog(isPresented: self.$cameraStore.showAddPhotoConfirmation, onCameraAction: {
            self.cameraStore.openCamera()
        }, onLibraryAction: {
            self.photoStore.openLibrary()
        })
        .withCameraAccess(cameraStore: self.cameraStore) { capturedImage in
            self.photoStore.reduce(action: .addImageFromCamera(capturedImage))
        }
        .photosPicker(isPresented: self.$photoStore.showLibrary, selection: Binding(get: { self.photoStore.state.selection },
                                                                                    set: { self.photoStore.reduce(action: .addImages($0)) }))
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                Rectangle() // Top divider
                    .fill(Color.black.opacity(0.025))
                    .frame(height: 3)

                POIBottomToolbar(item: self.pointOfInterestStore.pointOfInterest,
                                 duration: self.routes?.first?.duration != nil ? self.formatter
                                     .formatDuration(duration: self.routes?.first?.duration ?? 0) : nil,
                                 onStart: self.onStart,
                                 onDismiss: self.onDismiss,
                                 didDenyLocationPermission: self.didDenyLocationPermission,
                                 routes: self.routes, sheetStore: self.sheetStore,
                                 favoritesStore: self.favoritesStore)
                    .padding(.bottom)
                    .padding(.vertical)
                    .padding(.horizontal, 20)
                    .background(Color.white)
            }
        }
        .ignoresSafeArea()
        .alert("Location Needed",
               isPresented: self.$askToEnableLocation) {
            Button("Enable location in permissions") {
                self.openURL(URL(string: UIApplication.openSettingsURLString)!) // swiftlint:disable:this force_unwrapping
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable your location to get directions")
        }
        .task {
            await self.calculateRoute(for: self.pointOfInterestStore.pointOfInterest)
        }
        .onAppear {
            self.pointOfInterestStore.reApplyThePointOfInterestToTheMapIfNeeded()
        }
        // Displays a simple toast message when user tap save icon to save poi
        .simpleToast(isPresented: self.$favoritesStore.isMarkedAsFavourite,
                     options: SimpleToastOptions(alignment: .bottom, hideAfter: 2, animation: .easeIn, modifierType: .fade), content: {
                         Label(self.favoritesStore.labelMessage, systemSymbol: .checkmarkCircleFill)
                             .padding(.vertical, 12)
                             .padding(.horizontal, 12)
                             .background(Color.Colors.General._01Black)
                             .foregroundColor(Color.white)
                             .cornerRadius(10)
                     })
    }

    var tabView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack {
                    ForEach(POIOverviewView.Tab.allCases.filter {
                        $0 != .similar && ($0 != .photos || !self.pointOfInterestStore.pointOfInterest.mediaURLs.isEmpty)
                    }, id: \.self) { tab in
                        VStack {
                            Text(tab.description)
                                .hudhudFont(.subheadline)
                                .fontWeight(.semibold)
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
                        .padding(.horizontal, 10)
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

}

// MARK: - Private

private extension POIDetailSheet {

    var categoryView: some View { // Category · Subcategory
        Group {
            if let category = pointOfInterestStore.pointOfInterest.category {
                Text("\(category)\(self.pointOfInterestStore.pointOfInterest.subCategory.map { " · \($0)" } ?? "")")
                    .hudhudFont(.footnote)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
            }
        }
    }

    var ratingView: some View { // e.g. 4 ***** · (500)
        Group {
            if let rating = pointOfInterestStore.pointOfInterest.rating {
                HStack(spacing: 4) {
                    // Display rating with one decimal place
                    Text("\(rating, specifier: "%.1f")")
                        .hudhudFont(.subheadline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .fontWeight(.semibold)

                    // Star icons
                    ForEach(1 ... 5, id: \.self) { index in
                        Image(systemSymbol: .starFill)
                            .font(.footnote)
                            .foregroundColor(index <= Int(rating.rounded()) ? .yellow : .Colors.General._04GreyForLines)
                    }

                    // Optional ratings count with dot
                    if let ratingsCount = pointOfInterestStore.pointOfInterest.ratingsCount {
                        Text(" ·   (\(ratingsCount))")
                            .hudhudFont(.subheadline)
                            .foregroundStyle(Color.Colors.General._02Grey)
                    }
                }
                .padding(.horizontal, 6)
            } else {
                Text("No ratings")
                    .hudhudFont(.caption)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
    }

    var priceRangeView: some View { // · $$$
        Group {
            if let priceRangeValue = pointOfInterestStore.pointOfInterest.priceRange,
               let priceRange = HudHudPOI.PriceRange(rawValue: priceRangeValue) {
                Text(" ·   \(priceRange.displayValue)")
                    .hudhudFont(.subheadline)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
    }

    var accessibilityView: some View { // Wheelchair
        Group {
            if let wheelchairAccessible = self.pointOfInterestStore.pointOfInterest.isWheelchairAccessible, wheelchairAccessible {
                HStack {
                    Text(" · ")
                    Image(systemSymbol: .figureRoll)
                }
            }
        }
        .hudhudFont(.subheadline)
        .foregroundStyle(Color.Colors.General._02Grey)
    }

    var openStatusView: some View {
        Group {
            if let isOpen = self.pointOfInterestStore.pointOfInterest.isOpen,
               let openingHoursToday = self.pointOfInterestStore.pointOfInterest.openingHours?.first(where: { $0.day == currentWeekday }) {
                HStack {
                    Text("\(isOpen ? "Open" : "Closed") until \(self.nextAvailableTime(isOpen: isOpen, hours: openingHoursToday.hours))")
                        .hudhudFont(.subheadline)
                        .foregroundStyle(isOpen ? Color(.Colors.General._06DarkGreen) : Color(.Colors.General._12Red))
                }
            }
        }
    }

    var routeInformationView: some View {
        Group {
            if let route = routes?.first {
                HStack {
                    Image(systemSymbol: .carFill)
                        .hudhudFont(.caption2)
                        .foregroundStyle(Color.Colors.General._02Grey)
                    Text("\(self.formatter.formatDuration(duration: route.duration)) (\(self.formatter.formatDistance(distance: route.distance)))")
                        .hudhudFont(.subheadline)
                        .foregroundStyle(Color.Colors.General._02Grey)
                        .lineLimit(1)
                }
            }
        }
    }

    var openiningHoursView: some View {
        Group {
            if let openingHoursList = self.pointOfInterestStore.pointOfInterest.openingHours {
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

    func nextAvailableTime(isOpen: Bool, hours: [HudHudPOI.OpeningHours.TimeRange]) -> String {
        let nextTime = isOpen ? hours.last?.end : hours.first?.start
        if let nextHour = nextTime {
            return self.formatHour(nextHour)
        } else {
            return "Unknown"
        }
    }

    func formatHour(_ hour: Int) -> String {
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

    func calculateRoute(for item: ResolvedItem) async {
        do {
            let routes = try await self.routingStore.calculateRoutes(for: item)
            self.routes = routes
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
