//
//  RecentSearchResultsView.swift
//  HudHud
//
//  Created by Alaa . on 02/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapKit
import MapLibreSwiftUI
import SwiftUI

struct RecentSearchResultsView: View {
    let mapStore: MapStore
    @ObservedObject var searchStore: SearchViewStore
    @ScaledMetric var imageSize = 24
    let searchType: SearchViewStore.SearchType
    @State var EditFormViewIsShown: Bool = false
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    @State var clickedFavorite = FavoritesItem.favoriteForPreview

    var body: some View {
        ForEach(self.searchStore.recentViewedItem) { item in
            HStack(alignment: .center, spacing: 12) {
                Image(systemSymbol: item.symbol)
                    .resizable()
                    .font(.title2)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.imageSize, height: self.imageSize)
                    .foregroundStyle(.white)
                    .padding()
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
                    .layoutPriority(1)
                    .frame(minWidth: .leastNonzeroMagnitude)
                    .background(
                        item.color.mask(Circle())
                    )

                VStack(alignment: .leading) {
                    Text(item.title)
                        .hudhudFont(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text(item.subtitle)
                        .hudhudFont(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
                Spacer()
                if self.searchType == .favorites {
                    NavigationLink {
                        self.EditFormViewIsShown = true
                        self.camera = MapViewCamera.center(item.coordinate, zoom: 14)
                        self.clickedFavorite = FavoritesItem(id: UUID(), title: item.title, tintColor: item.color, item: item, type: item.category ?? "")
                        return EditFavoritesFormView(item: item, favoritesItem: self.clickedFavorite, camera: self.$camera)
                    } label: {
                        Text("+")
                            .foregroundStyle(Color(UIColor.label))
                    }
                }
            }
            .onTapGesture {
                let selectedItem = item
                let mapItems = [DisplayableRow.resolvedItem(item)]
                self.mapStore.selectedItem = selectedItem
                self.mapStore.displayableItems = mapItems
            }
        }
        .onDelete { indexSet in
            self.searchStore.recentViewedItem.remove(atOffsets: indexSet)
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    NavigationStack {
        RecentSearchResultsView(mapStore: .storeSetUpForPreviewing,
                                searchStore: .storeSetUpForPreviewing, searchType: .favorites)
    }
}

#Preview("EditFavoritesFormView") {
    let item: ResolvedItem = .artwork
    @State var favoriteItem: FavoritesItem = .init(id: UUID(), title: item.title, tintColor: item.color, item: item, type: item.category ?? "")
    @State var camera = MapViewCamera.center(item.coordinate, zoom: 14)
    @State var EditFormViewIsShown: Bool = true
    return NavigationStack {
        RecentSearchResultsView(mapStore: .storeSetUpForPreviewing,
                                searchStore: .storeSetUpForPreviewing, searchType: .favorites)
            .navigationDestination(isPresented: $EditFormViewIsShown) {
                EditFavoritesFormView(item: item, favoritesItem: favoriteItem, camera: $camera)
            }
    }
}
