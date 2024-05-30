//
//  RecentSearchResultsView.swift
//  HudHud
//
//  Created by Alaa . on 02/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapKit
import POIService
import SwiftUI

struct RecentSearchResultsView: View {
    let mapStore: MapStore
    let searchStore: SearchViewStore
    @ScaledMetric var imageSize = 24

    var body: some View {
        List {
            ForEach(self.searchStore.recentViewedItem, id: \.self) { item in
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
                            item.tintColor.mask(Circle())
                        )

                    VStack(alignment: .leading) {
                        Text(item.title)
                            .foregroundStyle(.primary)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        Text(item.subtitle)
                            .foregroundStyle(.secondary)
                            .font(.body)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .onTapGesture {
                    let selectedItem = item
                    let mapItems = [AnyDisplayableAsRow(item)]
                    self.mapStore.selectedItem = selectedItem
                    self.mapStore.displayableItems = mapItems
                }
            }
            .onMove(perform: self.moveAction)
            .onDelete { indexSet in
                self.searchStore.recentViewedItem.remove(atOffsets: indexSet)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
            .padding(.top)
        }
        .scrollDisabled(true)
        .aspectRatio(contentMode: .fill)
    }

    // MARK: - Internal

    @MainActor func moveAction(from source: IndexSet, to destination: Int) {
        self.searchStore.recentViewedItem.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    RecentSearchResultsView(mapStore: .storeSetUpForPreviewing,
                            searchStore: .storeSetUpForPreviewing)
}
