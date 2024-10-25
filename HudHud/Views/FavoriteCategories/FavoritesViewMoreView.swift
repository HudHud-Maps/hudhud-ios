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
import SwiftUI

// MARK: - FavoritesViewMoreView

struct FavoritesViewMoreView: View {

    // MARK: Properties

    @ObservedObject var searchStore: SearchViewStore
    @Bindable var sheetStore: SheetStore
    @State var actionSheetShown: Bool = false
    @State var searchSheetShown: Bool = false
    @State var clickedFavorite: FavoritesItem = .favoriteForPreview
    @Environment(\.dismiss) var dismiss
    @ObservedObject var favoritesStore: FavoritesStore
    @StateObject var filterStore = FilterStore()
    var navigationVisualization: NavigationVisualization

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                switch self.searchStore.searchType {
                case .returnPOILocation, .favorites:
                    Button("Cancel") {
                        self.dismiss()
                    }
                    .foregroundColor(.gray)
                    .padding(.trailing)
                case .selectPOI, .categories:
                    EmptyView()
                }
            }
            .background(.thickMaterial)
            .cornerRadius(12)

            Section { // show my favorites
                ForEach(self.favoritesStore.favoritesItems) { favorite in
                    if favorite.item != nil {
                        HStack {
                            FavoriteItemView(favorite: favorite)
                            Spacer()
                            Button {
                                self.actionSheetShown = true
                                self.clickedFavorite = favorite
                            } label: {
                                Text("...")
                                    .foregroundStyle(Color(UIColor.label))
                            }
                        }
                    }
                }
                .confirmationDialog("action", isPresented: self.$actionSheetShown) {
                    Button("Edit") {
                        self.sheetStore.pushSheet(
                            SheetViewData(
                                viewData: .editFavoritesForm(
                                    item: self.clickedFavorite.item ?? .starbucks,
                                    favoriteItem: self.clickedFavorite
                                )
                            )
                        )
                    }
                    Button("Delete", role: .destructive) {
                        self.favoritesStore.deleteFavorite(self.clickedFavorite)
                    }
                }
            }

            Section("Suggestions") {
                RecentSearchResultsView(
                    searchStore: self.searchStore,
                    searchType: .favorites,
                    sheetStore: self.sheetStore
                )
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button {
                self.searchSheetShown = true
            } label: {
                Image(systemSymbol: .plus)
            }
        )

        .sheet(isPresented: self.$searchSheetShown) {
            self.searchSheetView()
        }
        .onChange(of: self.searchSheetShown) {
            self.sheetStore.pushSheet(SheetViewData(viewData: .favorites))
        }
    }

    func searchSheetView() -> some View {
        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
//        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
        self.navigationVisualization.clear()
        let freshSearchViewStore = SearchViewStore(
            mapStore: freshMapStore,
            sheetStore: SheetStore(),
            navigationVisualization: navigationVisualization,
            filterStore: FilterStore(),
            mode: self.searchStore.mode
        )
        freshSearchViewStore.searchType = .favorites
        return SearchSheet(
            mapStore: freshMapStore,
            searchStore: freshSearchViewStore,
            trendingStore: TrendingStore(),
            sheetStore: self.sheetStore,
            filterStore: FilterStore()
        )
    }
}

#Preview {
    NavigationStack {
        FavoritesViewMoreView(
            searchStore: .storeSetUpForPreviewing,
            sheetStore: .storeSetUpForPreviewing,
            favoritesStore: .storeSetUpForPreviewing,
            navigationVisualization: .preview
        )
    }
}

// #Preview("testing title") {
//    @Previewable @State var isLinkActive = true
//    return NavigationStack {
//        Text("root view")
//            .navigationDestination(isPresented: $isLinkActive) {
//                FavoritesViewMoreView(
//                    searchStore: .storeSetUpForPreviewing,
//                    sheetStore: .storeSetUpForPreviewing,
//                    favoritesStore: .storeSetUpForPreviewing
//                )
//            }
//    }
// }
