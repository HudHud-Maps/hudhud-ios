//
//  PoiTileView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct PoiTileView: View {
	var poiTileData: PoiTileData
	var body: some View {
		VStack(alignment: .leading) {
			ZStack(alignment: .topLeading) {
				AsyncImage(url: URL(string: poiTileData.imageUrl ?? "")) { image in
					image
						.resizable()
						.scaledToFill()
						.frame(width: 175, height: 175)
				} placeholder: {
					ProgressView()
				}
				.background(.secondary)
				.cornerRadius(7.0)
				HStack {
					HStack(spacing: 5) {
						Image(systemSymbol: .starFill)
							.font(.footnote)
							.foregroundColor(.orange)
						Text(poiTileData.rating ?? "0")
							.foregroundStyle(.primary)
							.font(.system(.caption))
							.foregroundStyle(.background)
					}
					.padding(10)
					Spacer()
					HStack(spacing: 5) {
						Text(poiTileData.followersNumbers ?? "0")
							.foregroundStyle(.primary)
							.font(.system(.caption))
							.foregroundStyle(.background)
						Image(systemSymbol: poiTileData.isFollowed ? .heartFill : .heart)
							.font(.footnote)
							.foregroundColor(.orange)
					}
					.padding(10)
				}
				.frame(width: 175, alignment: .center)
			}
			VStack(alignment: .leading, spacing: 3) {
				Text(poiTileData.title)
					.font(.subheadline)
				HStack {
					Text("\(poiTileData.poiType) \u{2022} \(poiTileData.locationDistance ?? "") \u{2022} \(poiTileData.pricing?.rawValue ?? "")")
						.font(.callout)
						.foregroundStyle(.secondary)
				 }
			}
			.padding(.leading, 10)
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
	return PoiTileView(poiTileData: poi)
}
