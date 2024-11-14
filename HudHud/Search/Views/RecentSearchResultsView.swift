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

// MARK: - RecentSearchResultsView

struct RecentSearchResultsView: View {

    // MARK: Properties

    let searchStore: SearchViewStore
    let searchType: SearchViewStore.SearchType

    @ScaledMetric var imageSize = 24
    var sheetStore: SheetStore

    // MARK: Content

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
                    Text(item.subtitle ?? item.coordinate.formatted())
                        .hudhudFont(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
                Spacer()
                if self.searchType == .favorites {
                    Button("+") {
                        self.sheetStore.show(.editFavoritesForm(item: item))
                    }
                    .foregroundStyle(Color(.label))
                }
            }
            .onTapGesture {
                self.sheetStore.show(.pointOfInterest(item))
                switch self.searchType {
                case let .returnPOILocation(completion):
                    if self.searchStore.mapStore.selectedItem.value != nil {
                        completion(item)
                        self.sheetStore.popSheet()
                    }
                case .selectPOI, .categories, .favorites:
                    break
                }
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
        RecentSearchResultsView(
            searchStore: .storeSetUpForPreviewing,
            searchType: .favorites,
            sheetStore: .storeSetUpForPreviewing
        )
    }
}

// MARK: - EditFavoritesFormViewPreview

struct EditFavoritesFormViewPreview: PreviewProvider {

    static var previews: some View {
        let item = ResolvedItem.artwork
        let favoriteItem = FavoritesItem(id: UUID(),
                                         title: item.title,
                                         tintColor: .personalShopping,
                                         item: item,
                                         type: item.category ?? "")
        let favoritesStore = FavoritesStore()

        return NavigationStack {
            RecentSearchResultsView(
                searchStore: .storeSetUpForPreviewing,
                searchType: .favorites,
                sheetStore: .storeSetUpForPreviewing
            )
            .navigationDestination(isPresented: .constant(true)) {
                EditFavoritesFormView(item: .artwork, favoritesItem: favoriteItem, favoritesStore: favoritesStore, sheetStore: .storeSetUpForPreviewing)
            }
        }
        .previewDisplayName("EditFavoritesFormView")
    }
}
