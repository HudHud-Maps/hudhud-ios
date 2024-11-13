//
//  CategoriesBannerView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct CategoriesBannerView: View {

    // MARK: Properties

    var catagoryBannerData: [CatagoryBannerData]
    @ObservedObject var searchStore: SearchViewStore

    // MARK: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(self.catagoryBannerData) { category in
                    Button(category.title, systemImage: category.iconSystemName) {
                        Task {
                            await self.searchStore.fetch(category: category.title)
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44) // needed to make the button easier to tap
                    .buttonStyle(IconButton(backgroundColor: category.buttonColor ?? .white,
                                            foregroundColor: category.textColor ?? .black))
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    return VStack {
        CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: .storeSetUpForPreviewing)
        Spacer()
    }
}
