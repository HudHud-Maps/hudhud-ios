//
//  SearchSectionView.swift
//  HudHud
//
//  Created by Alaa . on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct SearchSectionView<Content: View>: View {
    let title: LocalizedStringResource
    let subview: Content

    var body: some View {
        Section(
            header: Text(
                "\(self.title)"
            ).font(
                .title3
            )
            .bold().foregroundStyle(
                .primary
            )
        ) {
            self.subview
                .backport.scrollClipDisabled()
                .padding(.top)
        }
    }

    // MARK: - Lifecycle

    init(title: LocalizedStringResource, @ViewBuilder subview: () -> Content) {
        self.title = title
        self.subview = subview()
    }
}

#Preview {
    SearchSectionView(title: "Favorites") {
        FavoriteCategoriesView(mapStore: .storeSetUpForPreviewing, searchStore: .storeSetUpForPreviewing)
    }
}
