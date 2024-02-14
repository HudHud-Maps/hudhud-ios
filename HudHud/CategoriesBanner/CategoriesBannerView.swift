//
//  CategoriesBannerView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct CategoriesBannerView: View {
	
	var CatagoryBannerData: [CatagoryBannerData]
	
	
    var body: some View {
		VStack{
			ScrollView(.horizontal){
				HStack(alignment: .top,spacing: 12){
					ForEach(self.CatagoryBannerData) { category in
						Button(category.title ?? "",systemImage: category.icon ?? "") {
							
							print("category \(category.title ?? "") pressed")
								
						}.buttonStyle(iconButton(backgroundColor: category.textColor ?? .white,foregroundColor: category.textColor ?? .black))
						
					}
				}.padding()
			}.scrollIndicators(.hidden)
			Spacer()
		}
    }
}

#Preview {
	let cateoryBannerFakeDate = [CatagoryBannerData(buttonColor: .white,textColor: .green, title: "Resturant", icon: "fork.knife"),CatagoryBannerData(buttonColor: .white,textColor: .brown, title: "Shop", icon: "bag.circle.fill"),CatagoryBannerData(buttonColor: .white,textColor: .orange, title: "Hotels", icon: "bed.double.fill"),CatagoryBannerData(buttonColor: .white,textColor: .yellow, title: "Coffee Shop", icon: "cup.and.saucer.fill")]
	return CategoriesBannerView(CatagoryBannerData: cateoryBannerFakeDate)
}

