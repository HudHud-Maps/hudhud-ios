//
//  POIBottomToolbar.swift
//  HudHud
//
//  Created by Alaa . on 09/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCoreFFI
import SwiftUI

// MARK: - POIBottomToolbar

struct POIBottomToolbar: View {

    // MARK: Properties

    @ObservedObject var favoritesStore: FavoritesStore
    let item: ResolvedItem
    let duration: String?
    let onStart: (([Route]?) -> Void)?
    let onDismiss: (() -> Void)?
    let didDenyLocationPermission: Bool?
    let routes: [Route]?
    let sheetStore: SheetStore
    @State var askToEnableLocation = false
    let directions: (() -> Void)?
    @Environment(\.openURL) var openURL

    // MARK: Lifecycle

    // Main initializer with most parameters (for POIDetailSheet)
    init(item: ResolvedItem,
         duration: String?,
         onStart: (([Route]?) -> Void)?,
         onDismiss: @escaping () -> Void,
         didDenyLocationPermission: Bool?,
         routes: [Route]?,
         sheetStore: SheetStore,
         favoritesStore: FavoritesStore) {
        self.item = item
        self.duration = duration
        self.onStart = onStart
        self.onDismiss = onDismiss
        self.didDenyLocationPermission = didDenyLocationPermission
        self.routes = routes
        self.directions = nil
        self.sheetStore = sheetStore
        self.favoritesStore = favoritesStore
    }

    // Secondary initializer with only item and directions (for SearchResultView)
    init(item: ResolvedItem,
         sheetStore: SheetStore,
         favoritesStore: FavoritesStore,
         directions: @escaping () -> Void) {
        self.item = item
        self.duration = nil
        self.onStart = nil
        self.onDismiss = nil
        self.didDenyLocationPermission = nil
        self.routes = nil
        self.directions = directions
        self.sheetStore = sheetStore
        self.favoritesStore = favoritesStore
    }

    // MARK: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                CategoryIconButton(icon: .arrowrightCircleIconFill,
                                   title: self.duration ?? "Directions",
                                   foregroundColor: .white,
                                   backgroundColor: Color.Colors.General._06DarkGreen) {
                    if self.didDenyLocationPermission == true {
                        self.askToEnableLocation = true
                    } else {
                        self.onStart?(self.routes)
                        self.directions?()
                    }
                }

                if let phone = item.phone, let url = URL(string: "tel://\(phone)") {
                    CategoryIconButton(icon: .phoneIcon,
                                       title: "Call",
                                       foregroundColor: Color.Colors.General._06DarkGreen,
                                       backgroundColor: Color.Colors.General._03LightGrey) {
                        self.openURL(url)
                    }
                }

                if let website = item.website {
                    CategoryIconButton(icon: .websiteIconFill,
                                       title: nil,
                                       foregroundColor: Color.Colors.General._06DarkGreen,
                                       backgroundColor: Color.Colors.General._03LightGrey) {
                        self.openURL(website)
                    }
                }

                CategoryIconButton(icon: self.favoritesStore.isFavorites(item: self.item) ? .saveIconFill : .saveIcon,
                                   title: nil,
                                   foregroundColor: Color.Colors.General._06DarkGreen,
                                   backgroundColor: Color.Colors.General._03LightGrey) {
                    if self.favoritesStore.isFavorites(item: self.item) { self.favoritesStore.deleteSavedFavorite(item: self.item)
                    } else {
                        self.favoritesStore.saveChanges(title: self.item.title,
                                                        tintColor: .personalShopping,
                                                        item: self.item,
                                                        description: self.item.description,
                                                        selectedType: self.item.category ?? "Other")
                    }
                    if self.favoritesStore.showLoginSheet {
                        self.sheetStore.show(.loginNeeded)
                    }
                }

                CategoryIconButton(icon: .shareIcon,
                                   title: nil,
                                   foregroundColor: Color.Colors.General._06DarkGreen,
                                   backgroundColor: Color.Colors.General._03LightGrey) {
                    // action
                    //  self.openURL()
                }
                // currently hidden since no url return from the backend
                .hidden()

                Spacer()
            }
        }
        .scrollDisabled(true)
    }
}

// MARK: - CategoryIconButton

private struct CategoryIconButton: View {

    // MARK: Properties

    let icon: ImageResource
    let title: String?
    let foregroundColor: Color
    let backgroundColor: Color
    let onClick: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: self.onClick) {
            if let title {
                // Show both icon and title
                Label(title, image: self.icon)
                    .foregroundColor(self.foregroundColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(self.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                // Show only icon
                Image(self.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(self.foregroundColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(self.backgroundColor)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    POIBottomToolbar(item: .ketchup, sheetStore: .storeSetUpForPreviewing, favoritesStore: FavoritesStore()) {}
}
