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
    // State variables for each filter
    @State private var sortSelection = "Relevance"
    @State private var priceSelection = "one"
    @State private var ratingSelection = "Any"
    @State private var scheduleSelection = "Any"
    @ObservedObject var searchStore: SearchViewStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading) {
            // Sort By Filter
            Text("Sort By")
            HudhudSegmentedPicker(selected: self.$sortSelection, options: [SegmentOption(value: "Relevance", label: .text("Relevance")), SegmentOption(value: "Distance", label: .text("Distance"))])
                .padding(.bottom)
            // Price Filter
            Text("Price")
            HudhudSegmentedPicker(
                selected: self.$priceSelection,
                options: [
                    SegmentOption(value: "one", label: .images(self.generateImages(for: "one", selection: self.priceSelection))),
                    SegmentOption(value: "two", label: .images(self.generateImages(for: "two", selection: self.priceSelection))),
                    SegmentOption(value: "three", label: .images(self.generateImages(for: "three", selection: self.priceSelection))),
                    SegmentOption(value: "four", label: .images(self.generateImages(for: "four", selection: self.priceSelection)))
                ]
            )
            .padding(.bottom)
            // Rating Filter
            Text("Rating")
            HudhudSegmentedPicker(selected: self.$ratingSelection, options: [SegmentOption(value: "Any", label: .text("Any")), SegmentOption(value: "3.5", label: .textWithSymbol("3.5", .starFill)), SegmentOption(value: "4.0", label: .textWithSymbol("4.0", .starFill)), SegmentOption(value: "4.5", label: .textWithSymbol("4.5", .starFill))])
                .padding(.bottom)
            // Work Schedule Filter
            Text("Work Schedule")
            HudhudSegmentedPicker(selected: self.$scheduleSelection, options: [SegmentOption(value: "Any", label: .text("Any")), SegmentOption(value: "Open", label: .text("Open")), SegmentOption(value: "Custom", label: .text("Custom"))])
                .padding(.bottom)
            Spacer()
            Divider().padding(-20)
            Button {
                self.sortSelection = "Relevance"
                self.priceSelection = "one"
                self.ratingSelection = "Any"
                self.scheduleSelection = "Any"
            } label: {
                Text("Reset")
                    .hudhudFont(.headline)
                    .foregroundStyle(Color.Colors.General._12Red)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .padding(.horizontal, 5)
        .navigationTitle("More Filters")
        .navigationBarItems(
            trailing:
            Button {
                self.applyFilters()
                self.dismiss()
            } label: {
                Text("Apply Filters")
                    .bold()
            }
        )
    }

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

    private func applyFilters() {
        self.searchStore.selectedFilters.removeAll()

        if self.sortSelection == "Distance" {
            self.searchStore.selectedFilters.append(.sort(.distance))
        } else {
            self.searchStore.selectedFilters.append(.sort(.relevance))
        }

        switch self.priceSelection {
        case "one":
            self.searchStore.selectedFilters.append(.priceRange(.cheap))
        case "two":
            self.searchStore.selectedFilters.append(.priceRange(.medium))
        case "three":
            self.searchStore.selectedFilters.append(.priceRange(.pricy))
        case "four":
            self.searchStore.selectedFilters.append(.priceRange(.expensive))
        default:
            break
        }

        switch self.ratingSelection {
        case "Any":
            self.searchStore.selectedFilters.append(.rating(.anyRating))
        case "3.5":
            self.searchStore.selectedFilters.append(.rating(.rating4))
        case "4.0":
            self.searchStore.selectedFilters.append(.rating(.rating4))
        case "4.5":
            self.searchStore.selectedFilters.append(.rating(.rating4andHalf))
        default:
            break
        }

        if self.scheduleSelection == "Open" {
            self.searchStore.selectedFilters.append(.openNow)
        }

        self.searchStore.updateDisplayedItems()
    }
}

#Preview {
    MoreFiltersView(searchStore: .storeSetUpForPreviewing)
}
