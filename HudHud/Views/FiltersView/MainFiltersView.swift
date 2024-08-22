//
//  MainFiltersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 19/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct MainFiltersView: View {

    @ObservedObject var searchStore: SearchViewStore

    var body: some View {
        HStack(spacing: 10) {
            Button {
                self.searchStore.selectedFilter = .openNow
            } label: {
                Text("Open Now")
                    .hudhudFont(size: 12, fontWeight: .semiBold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .foregroundStyle(self.searchStore.selectedFilter == .openNow ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._01Black))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(self.searchStore.selectedFilter == .openNow ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._04GreyForLines), lineWidth: 1)
                    )
            }
            Button {
                self.searchStore.selectedFilter = .topRated
            } label: {
                Text("Top Rated")
                    .hudhudFont(size: 12, fontWeight: .semiBold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .foregroundStyle(self.searchStore.selectedFilter == .topRated ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._01Black))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(self.searchStore.selectedFilter == .topRated ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._04GreyForLines), lineWidth: 1)
                    )
            }
            Spacer()
            Button(action: {
                self.searchStore.selectedFilter = .filter
            }, label: {
                Image(.filter)
                    .hudhudFont(.caption2)
                    .scaledToFit()
            })
        }
    }
}

#Preview {
    MainFiltersView(searchStore: .storeSetUpForPreviewing)
}
