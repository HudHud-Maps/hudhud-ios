//
//  FavoritesCategoriesView.swift
//  HudHud
//
//  Created by Alaa . on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct FavoritesCategoriesView: View {
	@Environment(\.colorScheme) var colorScheme
	let favCategoriesData: [FavCategoriesData] = [
		FavCategoriesData(title: "Home",
						  sfSymbol: "house.fill",
						  tintColor: .gray),
		FavCategoriesData(title: "Work",
						  sfSymbol: "bag.fill",
						  tintColor: .gray),
		FavCategoriesData(title: "School",
						  sfSymbol: "building.columns.fill",
						  tintColor: .gray)]
	let plusButton = FavCategoriesData(title: "Add",
									   sfSymbol: "plus.circle.fill",
									   tintColor: .green)
	var body: some View {
			HStack {
				ForEach(favCategoriesData.prefix(4), id: \.self) { favorite in
					FavCategoriesButton(favCategoriesData: favorite) {
						print("\(favorite.title) was pressed")
					}
				}
				FavCategoriesButton(favCategoriesData: plusButton) {
					print("\(plusButton.title) was pressed")
				}
				// to give the 4th category a space
				if favCategoriesData.count < 4 {
					Text("      ")
						.padding(.horizontal)
				}
		}
	}
}

#Preview {
	VStack(alignment: .leading) {
		HStack {
			Text("Favorites")
				.font(.system(.title))
				.bold()
				.lineLimit(1)
				.minimumScaleFactor(0.5)
			Spacer()
			Text("View More >")
				.lineLimit(1)
				.minimumScaleFactor(0.5)
		}
		FavoritesCategoriesView()
	}
	.padding()
}
