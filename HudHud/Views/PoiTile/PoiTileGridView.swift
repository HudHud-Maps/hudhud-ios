//
//  PoiTileGridView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import SwiftUI

struct PoiTileGridView: View {
    let rows: [GridItem] = [GridItem(.adaptive(minimum: 170))]
    var trendingPOIs: TrendingStore

    var body: some View {
        if let trendingPOI = self.trendingPOIs.trendingPOIs {
            ScrollView(.horizontal) {
                LazyHGrid(rows: self.rows, alignment: .top, spacing: 10) {
                    ForEach(trendingPOI) { poiTileGrid in
                        PoiTileView(poiTileData: poiTileGrid)
                    }
                }
            }
        } else {
            VStack(alignment: .leading) {
                Text("No Results")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Text("\(self.trendingPOIs.lastError?.localizedDescription ?? "error not found")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.leading)
        }
    }
}

#Preview {
    let poi = ResolvedItem(id: "Al-Narjs - Riyadh",
                           title: "Supermarket",
                           subtitle: "Al-Narjs - Riyadh",
                           category: "Cafe", type: .hudhud,
                           coordinate: CLLocationCoordinate2D(latitude: 24.79671388339593, longitude: 46.70810150540095),
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"),
                           rating: 2,
                           ratingCount: 25,
                           trendingImage: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")
    let poi1 = ResolvedItem(id: "Al-Narjs - Riyadh",
                            title: "Supermarket",
                            subtitle: "Al-Narjs - Riyadh",
                            category: "Cafe", type: .hudhud,
                            coordinate: CLLocationCoordinate2D(latitude: 24.79671388339593, longitude: 46.70810150540095),
                            phone: "0503539560",
                            website: URL(string: "https://hudhud.sa"),
                            rating: 2,
                            ratingCount: 25,
                            trendingImage: "https://img.freepik.com/free-photo/side-view-pide-with-ground-meat-cheese-hot-green-pepper-tomato-board_141793-5054.jpg?w=1380&t=st=1708506625~exp=1708507225~hmac=58a53cfdbb7f984c47750f046cbc91e3f90facb67e662c8da4974fe876338cb3")

    let trendingStroe = TrendingStore()
    trendingStroe.trendingPOIs = [poi, poi1]
    return PoiTileGridView(trendingPOIs: trendingStroe)
}
