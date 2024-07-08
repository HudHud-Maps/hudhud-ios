//
//  PoiTileView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import OSLog
import SFSafeSymbols
import SwiftLocation
import SwiftUI

// MARK: - PoiTileView

struct PoiTileView: View {
    var poiTileData: ResolvedItem
    @State var location: CLLocation?

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
                        Text("\(self.poiTileData.rating ?? 0, specifier: "%.1f")")
                            .foregroundStyle(.primary)
                            .font(.system(.caption))
                            .bold()
                            .foregroundStyle(.background)
                        Text("(\(self.poiTileData.ratingsCount ?? 0))")
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
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(self.poiTileData.title)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack {
                    Text("\(self.poiTileData.category ?? "") \(self.poiTileData.distance(from: self.location))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 3)
            }
            .frame(width: 130, alignment: .leading)
            .padding(.leading, 1)
        }
        .task {
            do {
                self.location = try await Location.forSingleRequestUsage.requestLocation().location
            } catch {
                Logger.poiData.error("Error requesting location, could not calculate distance for trending")
            }
        }
    }
}

private extension ResolvedItem {

    func distance(from location: CLLocation?) -> String {
        guard let location else { return "" }

        let distance = self.coordinate.distance(to: location.coordinate)
        return "\u{2022} \(distance.getDistanceString())"
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
                           ratingsCount: 25,
                           trendingImage: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")
    return PoiTileView(poiTileData: poi)
}
