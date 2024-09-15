//
//  MoreFiltersView.swift
//  HudHud
//
//  Created by Alaa . on 05/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

struct MoreFiltersView: View {

    // MARK: Properties

    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var filterStore: FilterStore

    @Environment(\.dismiss) private var dismiss

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            // Sort By Filter
            Text("Sort By")
            HudhudSegmentedPicker(selected: self.$filterStore.sortSelection, options: [SegmentOption(value: "Relevance", label: .text("Relevance")), SegmentOption(value: "Distance", label: .text("Distance"))])
                .padding(.bottom)
            // Price Filter
            Text("Price")
            HudhudSegmentedPicker(
                selected: self.$filterStore.priceSelection,
                options: [
                    SegmentOption(value: "one", label: .images(self.generateImages(for: "one", selection: self.filterStore.priceSelection))),
                    SegmentOption(value: "two", label: .images(self.generateImages(for: "two", selection: self.filterStore.priceSelection))),
                    SegmentOption(value: "three", label: .images(self.generateImages(for: "three", selection: self.filterStore.priceSelection))),
                    SegmentOption(value: "four", label: .images(self.generateImages(for: "four", selection: self.filterStore.priceSelection)))
                ]
            )
            .padding(.bottom)
            // Rating Filter
            Text("Rating")
            HudhudSegmentedPicker(selected: self.$filterStore.ratingSelection, options: [SegmentOption(value: "Any", label: .text("Any")), SegmentOption(value: "3.5", label: .textWithSymbol("3.5", .starFill)), SegmentOption(value: "4.0", label: .textWithSymbol("4.0", .starFill)), SegmentOption(value: "4.5", label: .textWithSymbol("4.5", .starFill))])
                .padding(.bottom)
            // Work Schedule Filter
            Text("Work Schedule")
            HudhudSegmentedPicker(selected: self.$filterStore.scheduleSelection, options: [SegmentOption(value: "Any", label: .text("Any")), SegmentOption(value: "Open", label: .text("Open")), SegmentOption(value: "Custom", label: .text("Custom"))])
                .padding(.bottom)
            Spacer()
            Divider().padding(-20)
            Button {
                self.filterStore.sortSelection = "Relevance"
                self.filterStore.priceSelection = "one"
                self.filterStore.ratingSelection = "Any"
                self.filterStore.scheduleSelection = "Any"
            } label: {
                Text("Reset")
                    .hudhudFont(.headline)
                    .foregroundStyle(Color.Colors.General._12Red)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .padding(.horizontal, 5)
        .navigationTitle("Filters")
        .navigationBarItems(
            trailing:
            Button {
                self.filterStore.applyFilters()
                self.dismiss()
            } label: {
                Text("Apply")
                    .bold()
            }
        )
    }

    // MARK: Functions

    func generateImages(for value: String, selection: String) -> [Image] {
        let isSelected = value == selection
        let image: Image = isSelected ? Image(.whiteDiamondStar) : Image(.diamondStar)
        let imageCount: Int = switch value {
        case "one":
            1
        case "two":
            2
        case "three":
            3
        case "four":
            4
        default:
            0
        }
        return Array(repeating: image, count: imageCount)
    }

}

#Preview {
    let filterStore = FilterStore()
    return MoreFiltersView(searchStore: .storeSetUpForPreviewing, filterStore: filterStore)
}
