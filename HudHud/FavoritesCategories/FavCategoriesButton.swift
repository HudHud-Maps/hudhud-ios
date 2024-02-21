//
//  FavCategoriesButton.swift
//  HudHud
//
//  Created by Alaa . on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct FavCategoriesButton: View {
	typealias ActionHandled = () -> Void
	let favCategoriesData: FavCategoriesData
	let handler: ActionHandled
	internal init(
		favCategoriesData: FavCategoriesData,
		handler: @escaping FavCategoriesButton.ActionHandled
	) {
		self.favCategoriesData = favCategoriesData
		self.handler = handler
	}
    var body: some View {
		Button {
			handler()
		} label: {
			VStack {
				ZStack {
					Circle()
						.tint(.white)
						.shadow(color: .black.opacity(0.15), radius: 10, y: 10)
					Image(systemSymbol: SFSymbol(rawValue: favCategoriesData.sfSymbol))
						.resizable()
						.scaledToFit()
						.tint(favCategoriesData.tintColor ?? .gray)
						.padding(20)
				}
				Text("\(favCategoriesData.title)")
					.tint(.primary)
					.dynamicTypeSize(.medium)
			}
		}
    }
}

#Preview {
	FavCategoriesButton(favCategoriesData: FavCategoriesData(title: "Home", sfSymbol: "house.fill", tintColor: .secondary)) {}
}
