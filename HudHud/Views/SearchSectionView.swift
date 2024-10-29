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

    // MARK: Lifecycle

    init(title: LocalizedStringResource, @ViewBuilder subview: () -> Content) {
        self.title = title
        self.subview = subview()
    }

    // MARK: Content

    var body: some View {
        Section(header: Text("\(self.title)").hudhudFont(size: 18, fontWeight: .semiBold)
            .foregroundStyle(Color.Colors.General._01Black)) {
                self.subview
                    .scrollClipDisabled()
                    .padding(.top)
            }
    }

}

#Preview {
    SearchSectionView(title: "Favorites") {
        FavoriteCategoriesView(sheetStore: .storeSetUpForPreviewing)
    }
}
