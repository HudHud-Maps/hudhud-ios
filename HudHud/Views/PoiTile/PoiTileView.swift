//
//  PoiTileView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import SFSafeSymbols
import SwiftUI

struct PoiTileView: View {
    var poiTileData: ResolvedItem

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: self.poiTileData.trendingImage ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 140)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.automatic)
                        .frame(width: 130, height: 140)
                        .background(.secondary)
                        .cornerRadius(7.0)
                }
                .background(.secondary)
                .cornerRadius(7.0)
                HStack {
                    HStack(spacing: 2) {
                        Image(systemSymbol: .starFill)
                            .font(.footnote)
                            .foregroundColor(.orange)
                        Text("\(self.poiTileData.rating ?? 0)")
                            .foregroundStyle(.primary)
                            .font(.system(.caption))
                            .bold()
                            .foregroundStyle(.background)
                        Text("(\(self.poiTileData.ratingCount ?? 0))")
                            .foregroundStyle(.primary)
                            .font(.system(.caption))
                            .bold()
                            .foregroundStyle(.background)
                    }
                    .padding(5)
                    Spacer()
                    // Currently hidding in v1
//                    HStack(spacing: 5) {
                    //						Text("\(self.poiTileData.rating ?? 0)")
//                            .foregroundStyle(.primary)
//                            .font(.system(.caption))
//                            .foregroundStyle(.background)
//                        Image(systemSymbol: self.poiTileData.isFollowed ? .heartFill : .heart)
//                            .font(.footnote)
//                            .foregroundColor(.orange)
//                    }
//                    .padding(10)
                }
                .frame(width: 130, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(self.poiTileData.title)
                    .font(.subheadline)
                HStack {
                    Text("\(self.poiTileData.category ?? "")")
                        // comment for now ..the distance should calculate based on user location
                        //		\u{2022} \(self.poiTileData.distance?.getDistanceString() ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 5)
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
    return PoiTileView(poiTileData: poi)
}
