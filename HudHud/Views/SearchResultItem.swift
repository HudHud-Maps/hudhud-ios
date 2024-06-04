//
//  SearchResultItem.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapKit
import SwiftUI

struct SearchResultItem: View {

    let prediction: any DisplayableAsRow
    @ObservedObject var searchViewStore: SearchViewStore
    @ScaledMetric var imageSize = 24
    @State var detailFormShown: Bool = false
    @State var clickedFav: FavoriteCategoriesData = .init(id: 3, title: "School",
                                                          sfSymbol: .buildingColumnsFill,
                                                          tintColor: .gray, item: .pharmacy, description: " ", type: "School")
    @State var clickedItem: ResolvedItem = .artwork

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemSymbol: self.prediction.symbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.imageSize, height: self.imageSize)
                .foregroundStyle(.white)
                .padding()
                .clipShape(Circle())
                .overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
                .layoutPriority(1)
                .frame(minWidth: .leastNonzeroMagnitude)
                .background(
                    self.prediction.tintColor.mask(Circle())
                )

            VStack(alignment: .leading) {
                Text(self.prediction.title)
                    .foregroundStyle(.primary)
                    .font(.headline)
                    .lineLimit(1)
                Text(self.prediction.subtitle)
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: {
                if self.searchViewStore.searchType == .favorites {
                    self.detailFormShown = true
                    if let resolvedItem = self.prediction as? ResolvedItem {
                        self.clickedItem = resolvedItem
                    }
                    self.clickedFav = FavoriteCategoriesData(id: .random(in: 100 ... 999), title: "\(self.clickedItem.title)", sfSymbol: self.clickedItem.symbol, tintColor: self.clickedItem.tintColor, type: self.clickedItem.category ?? "")
                } else {
                    self.searchViewStore.searchText = self.prediction.title
                }

            }, label: {
                Image(systemSymbol: self.searchViewStore.searchType == .favorites ? .plus : .arrowUpLeft)
            })
            .padding(.trailing)
            .foregroundStyle(.tertiary)
        }
        .padding(8)
        .fullScreenCover(isPresented: self.$detailFormShown, content: {
            let bindingCamera = Binding(
                get: { self.searchViewStore.mapStore.camera },
                set: { self.searchViewStore.mapStore.camera = $0 }
            )
            return EditFavoritesFormView(item: self.$clickedItem, newFavorite: self.$clickedFav, camera: bindingCamera)
        })
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    return SearchResultItem(prediction: PredictionItem(id: UUID().uuidString,
                                                       title: "Starbucks",
                                                       subtitle: "Coffee",
                                                       symbol: .cupAndSaucer,
                                                       type: .appleResolved), searchViewStore: .storeSetUpForPreviewing)
}
