//
//  FavoriteItemView.swift
//  HudHud
//
//  Created by Alaa . on 03/06/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - FavoriteItemView

struct FavoriteItemView: View {

    // MARK: Properties

    let favorite: FavoritesItem
    @ScaledMetric var imageSize = 20
    @ObservedObject var favoritesStore: FavoritesStore

    // MARK: Computed Properties

    private var symbolForFavorite: SFSymbol {
        if self.isHomeOrWork {
            return self.favorite.getSymbol(type: self.favorite.type)
        } else {
            return self.favorite.item?.symbol ?? .heart
        }
    }

    private var isHomeOrWork: Bool {
        self.favorite.type == FavoritesItem.Types.home || self.favorite.type == FavoritesItem.Types.work
    }

    private var foregroundColor: Color {
        self.isHomeOrWork ? Color.Colors.General._06DarkGreen : Color.Colors.General._02Grey
    }

    // MARK: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemSymbol: self.symbolForFavorite)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.imageSize, height: self.imageSize)
                .foregroundStyle(self.foregroundColor)
                .padding()
                .clipShape(Circle())
                .layoutPriority(1)
                .frame(width: 38)
                .background(Color.Colors.General._03LightGrey.mask(Circle()))

            VStack(alignment: .leading, spacing: 1) {
                Text(self.favorite.title)
                    .hudhudFontStyle(.labelSmall)
                    .foregroundStyle(Color.Colors.General._01Black)
                    .lineLimit(1)
                Text(self.favorite.item?.subtitle ?? "Save a location")
                    .hudhudFontStyle(.paragraphSmall)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(1)
            }
            Spacer()
            // Display the button at the right of the row in saved location page
            FavoriteButtonView(favorite: self.favorite, favoritesStore: self.favoritesStore)
        }
    }

}

// MARK: - FavoriteButtonView

// Display the button at the right of the row in saved location page
struct FavoriteButtonView: View {

    // MARK: Properties

    let favorite: FavoritesItem
    @ObservedObject var favoritesStore: FavoritesStore

    // MARK: Computed Properties

    private var isHomeOrWork: Bool {
        self.favorite.type == FavoritesItem.Types.home || self.favorite.type == FavoritesItem.Types.work
    }

    // MARK: Content

    var body: some View {
        if self.isHomeOrWork {
            // Handle Home/Work edit action
            Button {
                if self.favorite.item != nil {
                    self.favoritesStore.editFavoriteMenu = true
                }
            } label: {
                if self.favorite.item != nil {
                    Image(systemSymbol: .ellipsis)
                        .foregroundStyle(Color.Colors.General._02Grey)
                } else {
                    Image(systemSymbol: .chevronRight)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
            }
            .padding(.trailing)
        } else {
            // Handle saved location unSave
            Button {
                if let favorite = favorite.item {
                    self.favoritesStore.deleteSavedFavorite(item: favorite)
                }
            } label: {
                if let item = favorite.item {
                    Image(self.favoritesStore.isFavorites(item: item) ? .saveIconFill : .saveIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color.Colors.General._10GreenMain)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.Colors.General._03LightGrey)
                        .clipShape(Circle())
                }
            }
        }
    }

}

#Preview {
    HStack {
        FavoriteItemView(favorite: FavoritesItem.favoriteForPreview, favoritesStore: FavoritesStore())
        Spacer()
    }
}
