//
//  SearchSectionView.swift
//  HudHud
//
//  Created by Alaa . on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct SearchSectionView<Content: View>: View {
	let title: String
	let subview: Content

	var body: some View {
		VStack {
			HStack {
				Text("\(self.title)")
					.font(.title3)
					.bold()
				Spacer()
			}
			ScrollView(.horizontal) {
				self.subview
			}
		}
	}

	// MARK: - Lifecycle

	init(title: String, @ViewBuilder subview: () -> Content) {
		self.title = title
		self.subview = subview()
	}
}

#Preview {
	SearchSectionView(title: "Favorites") {
		FavoriteCategoriesView()
	}
}
