//
//  CategoriesBannerView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct CategoriesBannerView: View {
	var catagoryBannerData: [CatagoryBannerData]
    var body: some View {
		VStack {
			ScrollView(.horizontal) {
				HStack(alignment: .top, spacing: 12) {
					ForEach(self.catagoryBannerData) { category in
						Button(category.title, systemImage: category.iconSystemName) {
							print("category \(category.title) pressed")
						}.buttonStyle(IconButton(backgroundColor: category.buttonColor ?? .white, foregroundColor: category.textColor ?? .black))
					}
				}
				.padding()
			}
			.scrollIndicators(.hidden)
		}
    }
}

#Preview {
	let cateoryBannerFakeDate = [
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .green,
			title: "Resturant",
			iconSystemName: "fork.knife"
		),
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .brown,
			title: "Shop",
			iconSystemName: "bag.circle.fill"
		),
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .orange,
			title: "Hotels",
			iconSystemName: "bed.double.fill"
		),
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .yellow,
			title: "Coffee Shop",
			iconSystemName: "cup.and.saucer.fill"
		)
	]
	return VStack{
		CategoriesBannerView(catagoryBannerData: cateoryBannerFakeDate)
		Spacer()
	}
}
