//
//  MainFiltersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 19/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct MainFiltersView: View {

    enum filterType {
        case openNow
        case topRated
        case filter
    }

    @State private var selectedFilter: filterType? = nil

    var body: some View {
        HStack(spacing: 10) {
            Button {
                Task {
                    self.selectedFilter = .openNow
                    print("Open Now")
                }
            } label: {
                Text("Open Now")
                    .hudhudFont(size: 12, fontWeight: .semiBold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .foregroundStyle(self.selectedFilter == .openNow ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._01Black))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(self.selectedFilter == .openNow ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._04GreyForLines), lineWidth: 1)
                    )
            }
            Button {
                Task {
                    self.selectedFilter = .topRated
                }
            } label: {
                Text("Top Rated")
                    .hudhudFont(size: 12, fontWeight: .semiBold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .foregroundStyle(self.selectedFilter == .topRated ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._01Black))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(self.selectedFilter == .topRated ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._04GreyForLines), lineWidth: 1)
                    )
            }
            Spacer()
            Button(action: {
                self.selectedFilter = .filter
            }, label: {
                Image(.filter)
                    .hudhudFont(.caption2)
                    .scaledToFit()
            })
        }
    }
}

#Preview {
    MainFiltersView()
}
