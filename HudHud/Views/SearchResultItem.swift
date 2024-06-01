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
                self.searchViewStore.searchText = self.prediction.title
            }, label: {
                Image(systemSymbol: .arrowUpLeft)
            })
            .padding(.trailing)
            .foregroundStyle(.tertiary)
        }
        .padding(8)
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    SearchResultItem(prediction: PredictionItem(id: UUID().uuidString,
                                                title: "Starbucks",
                                                subtitle: "Coffee",
                                                symbol: .cupAndSaucer,
                                                type: .appleResolved),
                     searchViewStore: .storeSetUpForPreviewing)
}
