//
//  FavoriteCategoriesView.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct FavoriteCategoriesView: View {
	let favoriteCategoriesData: [FavoriteCategoriesData] = [
		FavoriteCategoriesData(title: "Home",
						  sfSymbol: "house.fill",
						  tintColor: .gray),
		FavoriteCategoriesData(title: "Work",
						  sfSymbol: "bag.fill",
						  tintColor: .gray),
		FavoriteCategoriesData(title: "School",
						  sfSymbol: "building.columns.fill",
						  tintColor: .gray)]
	let plusButton = FavoriteCategoriesData(title: "Add",
									   sfSymbol: "plus.circle.fill",
									   tintColor: .green)
	var body: some View {
		ScrollView(.horizontal) {
			HStack {
				ForEach(favoriteCategoriesData.prefix(4), id: \.self) { favorite in
					Button {
						print("\(favorite.title) was pressed")
					} label: {
						Text(favorite.title)
					}
					.buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.sfSymbol, tintColor: favorite.tintColor))
				}
				Button {
					print("\(plusButton.title) was pressed")
				} label: {
					Text(plusButton.title)
				}.buttonStyle(FavoriteCategoriesButton(sfSymbol: plusButton.sfSymbol, tintColor: plusButton.tintColor))
			}
				Spacer()
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
		FavoriteCategoriesView()
	}
	.padding()
}

