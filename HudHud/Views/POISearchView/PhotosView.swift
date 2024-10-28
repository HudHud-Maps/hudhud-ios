//
//  PhotosView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct PhotosView<Content, Item, ID>: View where Content: View, ID: Hashable, Item: RandomAccessCollection, Item.Element: Hashable {

    // MARK: Properties

    var content: (Item.Element) -> Content
    var items: Item
    var id: KeyPath<Item.Element, ID>
    var spacing: CGFloat

    // MARK: Lifecycle

    init(items: Item, id: KeyPath<Item.Element, ID>, spacing: CGFloat = 5, @ViewBuilder content: @escaping (Item.Element) -> Content) {
        self.content = content
        self.items = items
        self.id = id
        self.spacing = spacing
    }

    // MARK: Content

    var body: some View {
        LazyVStack(spacing: self.spacing) {
            // Display the first image separately in a a bigger layout
            if let firstItem = items.first {
                self.firstImageView(item: firstItem)
            }

            // Loop through remaining images and display each 3 images in a custom layout
            ForEach(Array(self.generateRows().enumerated()), id: \.offset) { index, image in
                self.imagesSectionView(images: image, isType1: index % 2 == 0)
            }
        }
    }

    // View for the first image, styled differently (Big)
    @ViewBuilder
    func firstImageView(item: Item.Element) -> some View {
        self.content(item)
            .frame(height: 250)
    }

    // View to display of each 3 images
    @ViewBuilder
    func imagesSectionView(images: [Item.Element], isType1: Bool) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = (proxy.size.height - self.spacing) / 2
            let columnWidth = (width > 0 ? ((width - (spacing * 2)) / 3) : 0)

            HStack(alignment: .top, spacing: self.spacing) {
                // Layout Type 1: One image on the left, and two stacked images on the right
                if isType1 {
                    self.safeView(images: images, index: 0)
                    VStack(spacing: self.spacing) {
                        self.safeView(images: images, index: 1)
                            .frame(height: height)
                        self.safeView(images: images, index: 2)
                            .frame(height: height)
                    }
                    .frame(width: columnWidth)
                } else {
                    // Layout Type 2: Two stacked images on the left, and one image on the right
                    VStack(spacing: self.spacing) {
                        self.safeView(images: images, index: 0)
                            .frame(height: height)
                        self.safeView(images: images, index: 1)
                            .frame(height: height)
                    }
                    .frame(width: columnWidth)
                    self.safeView(images: images, index: 2)
                }
            }
        }
        .frame(height: 250)
    }

    // Safe view rendering for items in the row, preventing out-of-bounds access
    @ViewBuilder
    func safeView(images: [Item.Element], index: Int) -> some View {
        if images.count > index {
            self.content(images[index])
        }
    }

    // MARK: Functions

    // Generate rows of images, grouping them in sets of 3 for display in rows
    func generateRows() -> [[Item.Element]] {
        var rows: [[Item.Element]] = []
        var currentRow: [Item.Element] = []

        // Iterate over items, skipping the first item (already displayed separately)
        for item in self.items.dropFirst() {
            currentRow.append(item)
            // When 3 items are accumulated, add the row to the list and start a new row
            if currentRow.count == 3 {
                rows.append(currentRow)
                currentRow.removeAll()
            }
        }

        // Append any remaining items that didn’t fill a full row of 3
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }
}
