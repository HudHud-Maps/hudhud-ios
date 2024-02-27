//
//  PoiTileView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import SFSafeSymbols
import SwiftUI

struct PoiTileView: View {
	var poiTileData: PoiTileData

	var body: some View {
		VStack(alignment: .leading) {
			ZStack(alignment: .topLeading) {
				AsyncImage(url: self.poiTileData.imageUrl) { image in
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
						Text(self.poiTileData.rating ?? "0")
							.foregroundStyle(.primary)
							.font(.system(.caption))
							.foregroundStyle(.background)
					}
					.padding(10)
					Spacer()
					HStack(spacing: 5) {
						Text(self.poiTileData.followersNumbers ?? "0")
							.foregroundStyle(.primary)
							.font(.system(.caption))
							.foregroundStyle(.background)
						Image(systemSymbol: self.poiTileData.isFollowed ? .heartFill : .heart)
							.font(.footnote)
							.foregroundColor(.orange)
					}
					.padding(10)
				}
				.frame(width: 175, alignment: .center)
			}
			VStack(alignment: .leading, spacing: 3) {
				Text(self.poiTileData.title)
					.font(.subheadline)
				HStack {
					Text("\(self.poiTileData.poiType) \u{2022} \(self.poiTileData.grtDistanceString()) \u{2022} \(self.poiTileData.pricing?.rawValue ?? "")")
						.font(.caption)
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
		imageUrl: URL(string: "https://www.adobe.com/content/dam/cc/us/en/creative-cloud/photography/discover/food-photography/CODERED_B1_food-photography_p4b_690x455.jpg.img.jpg"),
		poiType: "Cafe",
		locationDistance: CLLocation(latitude: 24.69239471955797, longitude: 46.633261389241845).distance(from: CLLocation(latitude: 24.722823776812756, longitude: 46.626575919314305)),
		rating: "4.0",
		followersNumbers: "20",
		isFollowed: false,
		pricing: .medium
	)
	return PoiTileView(poiTileData: poi)
}
