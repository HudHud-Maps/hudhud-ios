//
//  PoiTileGridView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct PoiTileGridView: View {
	let poiTileGrid: [PoiTileData]
	let columns: [GridItem] = [GridItem(.adaptive(minimum: 170))]
	var body: some View {
		ScrollView {
			LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
				ForEach(self.poiTileGrid) { poiTileGrid in
					PoiTileView(poiTileData: poiTileGrid)
				}
			}
			.padding(20)
		}
	}
}
#Preview {
	let poi = PoiTileData(
		title: "Laduree",
		imageUrl: "https://www.adobe.com/content/dam/cc/us/en/creative-cloud/photography/discover/food-photography/CODERED_B1_food-photography_p4b_690x455.jpg.img.jpg",
		poiType: "Cafe",
		locationDistance: "15.0 km",
		rating: "4.0",
		followersNumbers: "20",
		isFollowed: false,
		pricing: .medium
	)
	let poi1 = PoiTileData(
		title: "Off white",
		imageUrl: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77",
		poiType: "Resturant",
		locationDistance: "9.3 km",
		rating: "2.5",
		followersNumbers: "69",
		isFollowed: true,
		pricing: .high
	)
	let poi2 = PoiTileData(
		title: "Red Sea",
		imageUrl: "https://img.freepik.com/free-photo/meat-burger-wooden-board-french-fries-side-view_141793-2388.jpg?t=st=1708506403~exp=1708507003~hmac=c82d36abb17b2ae727770a011ab20c5d07aeb6f9ce6f0488be6bbd762838c8be",
		poiType: "Shop",
		locationDistance: "4.3 km",
		rating: "3.5",
		followersNumbers: "3598",
		isFollowed: false,
		pricing: .low
	)
	let poi3 = PoiTileData(
		title: "Flour & firewood",
		imageUrl: "https://img.freepik.com/free-photo/side-view-pide-with-ground-meat-cheese-hot-green-pepper-tomato-board_141793-5054.jpg?w=1380&t=st=1708506625~exp=1708507225~hmac=58a53cfdbb7f984c47750f046cbc91e3f90facb67e662c8da4974fe876338cb3",
		poiType: "Resturant",
		locationDistance: "22 km",
		rating: "5.0",
		followersNumbers: "200",
		isFollowed: true,
		pricing: .medium
	)
	return PoiTileGridView(poiTileGrid: [poi, poi1, poi2, poi3])
}
