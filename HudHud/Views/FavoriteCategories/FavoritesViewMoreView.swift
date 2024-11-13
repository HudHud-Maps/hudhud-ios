//
//  FavoritesViewMoreView.swift
//  HudHud
//
//  Created by Alaa . on 30/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapKit
import MapLibreSwiftUI
import SimpleToast
import SwiftUI

// MARK: - FavoritesViewMoreView

struct FavoritesViewMoreView: View {

    // MARK: Properties

    @Environment(\.dismiss) var dismiss
    @Bindable var sheetStore: SheetStore
    @StateObject var favoritesStore: FavoritesStore

    // MARK: Content

    var body: some View {
        NavigationStack {
            Divider()
            ZStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        Section {
                            // Display Static "Home" and "Work" Favorites
                            ForEach(FavoritesItem.favoritesInit, id: \.id) { favorite in
                                FavoriteItemView(favorite: favorite, favoritesStore: self.favoritesStore)
                                    .onTapGesture {
                                        // currently, nothing will show ... but in the next ticket ..we will implement saving location for home and
                                        // work.
                                        if let item = favorite.item {
                                            self.sheetStore.show(.pointOfInterest(item))
                                        }
                                    }
                            }
                        }
                        Divider()
                            .padding(.vertical)
                        // Display user's saved favorites or a no saved location view if there are none
                        if self.favoritesStore.favoritesItems.isEmpty {
                            Spacer()
                        } else {
                            Section {
                                ForEach(self.favoritesStore.favoritesItems) { favorite in
                                    if favorite.item != nil {
                                        FavoriteItemView(favorite: favorite, favoritesStore: self.favoritesStore)
                                            .background(.white)
                                            .onTapGesture {
                                                if let item = favorite.item {
                                                    self.dismiss()
                                                    self.sheetStore.show(.pointOfInterest(item))
                                                }
                                            }
                                    }
                                }
                                .confirmationDialog("action", isPresented: self.$favoritesStore.editFavoriteMenu) {
                                    Button("Edit") {
                                        // Edti action for edting home/work
                                    }
                                    Button("Delete", role: .destructive) {
                                        // Delete action for Deleting home/work
                                    }
                                }
                            }
                        }
                    }
                }
                if self.favoritesStore.favoritesItems.isEmpty {
                    NoSavedLocationsView()
                }
            }
            .padding(.top)
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Saved Locations")
            .navigationBarItems(leading: Button {
                self.dismiss()
            } label: {
                Image(systemSymbol: .chevronBackward)
                    .resizable()
                    .frame(width: 12, height: 20)
                    .accentColor(Color.Colors.General._01Black)
                    .shadow(radius: 26)
                    .accessibilityLabel("Go Back")
            })
            // Displays a simple toast message when user tap save icon to save poi
            .simpleToast(isPresented: self.$favoritesStore.isMarkedAsFavourite,
                         options: SimpleToastOptions(alignment: .bottom, hideAfter: 2)) {
                HStack {
                    Label(self.favoritesStore.labelMessage, systemSymbol: .checkmarkCircleFill)
                    Text(" | ")
                        .foregroundColor(Color.Colors.General._02Grey)
                    Button {
                        self.favoritesStore.undoDelete()
                    } label: {
                        Text("Undo")
                            .hudhudFontStyle(.labelSmall)
                            .foregroundColor(Color.Colors.General._10GreenMain)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color.Colors.General._01Black)
                .foregroundColor(Color.white)
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - NoSavedLocationsView

struct NoSavedLocationsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Image(uiImage: .POI_PIN)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)

            VStack(spacing: 12) {
                Text("No Saved Locations")
                    .hudhudFontStyle(.labelMedium)
                    .foregroundStyle(Color.Colors.General._01Black)

                Text("Your saved locations will appear here")
                    .hudhudFontStyle(.paragraphMedium)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
        .padding(.top)
    }
}

#Preview {
    NavigationStack {
        FavoritesViewMoreView(sheetStore: .storeSetUpForPreviewing,
                              favoritesStore: .storeSetUpForPreviewing)
    }
}

#Preview("testing title") {
    @Previewable @State var isLinkActive = true
    return NavigationStack {
        Text("root view")
            .navigationDestination(isPresented: $isLinkActive) {
                FavoritesViewMoreView(sheetStore: .storeSetUpForPreviewing,
                                      favoritesStore: .storeSetUpForPreviewing)
            }
    }
}
