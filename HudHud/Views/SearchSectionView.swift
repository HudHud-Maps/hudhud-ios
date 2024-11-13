//
//  SearchSectionView.swift
//  HudHud
//
//  Created by Alaa . on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct SearchSectionView<Content: View>: View {

    // MARK: Properties

    let title: LocalizedStringResource
    let subview: Content
    let onViewMore: () -> Void

    // MARK: Lifecycle

    init(title: LocalizedStringResource, @ViewBuilder subview: () -> Content, onViewMore: @escaping () -> Void) {
        self.title = title
        self.subview = subview()
        self.onViewMore = onViewMore
    }

    // MARK: Content

    var body: some View {
        Section(header: HStack(alignment: .bottom) {
            Text("\(self.title)")
                .hudhudFontStyle(.headingSmall)
                .bold()
                .foregroundStyle(Color.Colors.General._01Black)

            Spacer()

            Button(action: self.onViewMore) {
                HStack(spacing: 3) {
                    Text("View More")
                        .hudhudFontStyle(.paragraphSmall)
                        .foregroundStyle(Color.Colors.General._02Grey)
                    Image(systemSymbol: .chevronRight)
                        .font(.caption)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }.padding(.trailing, 2)
            }
        }) {
            self.subview
                .scrollClipDisabled()
                .padding(.top)
        }
    }

}

#Preview {
    SearchSectionView(title: "Favorites") {
        FavoriteCategoriesView(sheetStore: .storeSetUpForPreviewing, favoritesStore: FavoritesStore())
    } onViewMore: {}
}
