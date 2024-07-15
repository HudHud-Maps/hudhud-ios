//
//  SearchResultItemView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapKit
import SFSafeSymbols
import SwiftUI

// MARK: - SearchResultItemView

struct SearchResultItemView: View {

    let item: SearchResultItem
    @Binding var searchText: String
    @ScaledMetric var imageSize = 24

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemSymbol: self.item.symbol)
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
                    self.item.color.mask(Circle())
                )

            VStack(alignment: .leading) {
                Text(self.item.title)
                    .foregroundStyle(.primary)
                    .font(.headline)
                    .lineLimit(1)
                Text(self.item.subtitle)
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: {
                self.searchText = self.item.title
            }, label: {
                Image(systemSymbol: .arrowUpLeft)
            })
            .padding(.trailing)
            .foregroundStyle(.tertiary)
        }
        .padding(8)
    }

    // MARK: - Lifecycle

    init(item: SearchResultItem, searchText: Binding<String>?) {
        self.item = item
        self._searchText = searchText ?? .constant("")
    }
}

// MARK: - SearchResultItem

struct SearchResultItem {
    private let displayableRow: DisplayableRow

    var symbol: SFSymbol {
        switch self.displayableRow {
        case let .category(category):
            category.icon
        case let .resolvedItem(resolvedItem):
            resolvedItem.symbol
        case let .predictionItem(predictionItem):
            predictionItem.symbol
        }
    }

    var title: String {
        switch self.displayableRow {
        case let .category(category):
            category.name
        case let .resolvedItem(resolvedItem):
            resolvedItem.title
        case let .predictionItem(predictionItem):
            predictionItem.title
        }
    }

    var subtitle: String {
        switch self.displayableRow {
        case .category:
            ""
        case let .resolvedItem(resolvedItem):
            resolvedItem.subtitle
        case let .predictionItem(predictionItem):
            predictionItem.subtitle
        }
    }

    public var color: Color {
        switch self.displayableRow {
        case let .category(category):
            category.color
        case let .resolvedItem(resolvedItem):
            resolvedItem.color
        case .predictionItem:
            Color(.systemRed)
        }
    }

    // MARK: - Lifecycle

    init(_ displayableRow: DisplayableRow) {
        self.displayableRow = displayableRow
    }
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    @State var searchText: String = ""
    return SearchResultItemView(
        item: SearchResultItem(.predictionItem(PredictionItem(
            id: UUID().uuidString,
            title: "Starbucks",
            subtitle: "Coffee",
            type: .appleResolved
        ))),
        searchText: $searchText
    )
}
