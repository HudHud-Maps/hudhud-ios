//
//  FavoriteItemView.swift
//  HudHud
//
//  Created by Alaa . on 03/06/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct FavoriteItemView: View {

    // MARK: Properties

    let favorite: FavoritesItem
    @ScaledMetric var imageSize = 24

    // MARK: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemSymbol: self.favorite.getSymbol(type: self.favorite.type))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.imageSize, height: self.imageSize)
                .foregroundStyle(.white)
                .padding()
                .clipShape(Circle())
                .overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
                .layoutPriority(1)
                .frame(minWidth: .leastNonzeroMagnitude)
                .background((self.favorite.item?.color ?? Color.gray).mask(Circle()))

            VStack(alignment: .leading) {
                Text(self.favorite.title)
                    .foregroundStyle(.primary)
                    .font(.headline)
                    .lineLimit(1)
                Text(self.favorite.item?.subtitle ?? "Address Not Available")
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    HStack {
        FavoriteItemView(favorite: FavoritesItem.favoriteForPreview)
        Spacer()
    }
}
