//
//  SearchSectionsView.swift
//  HudHud
//
//  Created by Alaa . on 16/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
//
import CoreLocation
import SwiftUI

struct SearchSectionsView: View {
	@State var sections: [SearchSectionData<AnyView, AnyView>]

	var body: some View {
		NavigationView {
			List {
				ForEach(self.sections, id: \.sectionTitle) { section in
					HStack {
						Text(section.sectionTitle)
							.font(.title3)
							.bold()
						Spacer()
						if let destination = section.destination {
							NavigationLink("View More", destination: destination)
								.font(.headline)
								.foregroundStyle(.secondary)
								.fixedSize()
						}
					}
					ScrollView(.horizontal) {
						section.subview
					}
					.listRowSeparator(.hidden)
				}
			}
			.listStyle(.plain)
		}
	}
}

#Preview {
	let pointA = CLLocation(latitude: 24.69239471955797, longitude: 46.633261389241845)
	let pointB = CLLocation(latitude: 24.722823776812756, longitude: 46.626575919314305)

	let poi = PoiTileData(title: "Laduree",
						  imageUrl: URL(string: "https://www.adobe.com/content/dam/cc/us/en/creative-cloud/photography/discover/food-photography/CODERED_B1_food-photography_p4b_690x455.jpg.img.jpg"),
						  poiType: "Cafe",
						  locationDistance: pointA.distance(from: pointB),
						  rating: "4.0",
						  followersNumbers: "20",
						  isFollowed: false,
						  pricing: .medium)

	let sections: [SearchSectionData<AnyView, AnyView>] = [
		SearchSectionData(sectionTitle: "Favorites", destination: nil as AnyView?, subview: AnyView(FavoriteCategoriesView())),
		SearchSectionData(sectionTitle: "Trending", destination: AnyView(FavoriteCategoriesView()), subview: AnyView(PoiTileView(poiTileData: poi)))
	]
	return SearchSectionsView(sections: sections)
}
