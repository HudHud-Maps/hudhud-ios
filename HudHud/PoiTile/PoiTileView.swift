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
				} placeholder: {
					ProgressView()
				}
				.frame(width: UIScreen.main.bounds.width/2.3, height: UIScreen.main.bounds.width/2.3)
				.background(.secondary)
				.cornerRadius(7.0)
				HStack {
					HStack(spacing: 5) {
						Image(systemSymbol: .starFill)
							.resizable()
							.frame(width: 10, height: 10)
							.foregroundColor(.orange)
						Text(poiTileData.rating ?? "0")
							.foregroundStyle(.primary)
							.font(.system(size: 12))
							.foregroundStyle(.background)
					}
					.padding(10)
					Spacer()
					HStack(spacing: 5) {
						Text(poiTileData.followersNumbers ?? "0")
							.foregroundStyle(.primary)
							.font(.system(size: 12))
							.foregroundStyle(.background)
						Image(systemSymbol: poiTileData.isFollowed ? .heartFill : .heart)
							.resizable()
							.frame(width: 10, height: 10)
							.foregroundColor(.orange)
					}
					.padding(10)
				}
				.frame(width: UIScreen.main.bounds.width/2.3, alignment: .center)
			}
			VStack(alignment: .leading, spacing: 3) {
				Text(poiTileData.title)
					.font(.subheadline)
				HStack {
					TextDetail(title: poiTileData.poiType)
					CircleShape()
					TextDetail(title: poiTileData.locationDistance ?? "2.3 km")
					CircleShape()
					TextDetail(title: poiTileData.pricing?.rawValue ?? "$")
				 }
			}
			.padding(.leading, 10)
		}
	}
}
struct TextDetail: View {
	var title: String
	var body: some View {
		Text(title)
			.font(.caption)
			.foregroundStyle(.secondary)
	}
}
#Preview {
	let poi = PoiTileData(
		title: "Off white",
		imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg",
		poiType: "Resturant",
		locationDistance: "4.3 KM",
		rating: "4.0",
		followersNumbers: "20",
		isFollowed: true,
		pricing: .high
	)
	return PoiTileView(poiTileData: poi)
}
