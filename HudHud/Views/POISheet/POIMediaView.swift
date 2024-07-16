//
//  POIMediaView.swift
//  HudHud
//
//  Created by Alaa . on 14/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import SwiftUI

struct POIMediaView: View {
    var item: ResolvedItem

    var body: some View {
        if let mediaURLs = item.mediaURLs {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(mediaURLs, id: \.url) { media in
                        AsyncImage(url: URL(string: media.url ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .scaledToFill()
                                .frame(width: 160, height: 140)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.automatic)
                                .frame(width: 160, height: 140)
                                .background(.secondary)
                                .cornerRadius(10)
                        }
                        .background(.secondary)
                        .cornerRadius(10)
                    }
                }
                .padding(.leading)
            }
        }
    }
}

#Preview {
    let mediaURLs = [MediaURLs(type: "image", url: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77"), MediaURLs(type: "image", url: "https://img.freepik.com/free-photo/seafood-sushi-dish-with-details-simple-black-background_23-2151349421.jpg?t=st=1720950213~exp=1720953813~hmac=f62de410f692c7d4b775f8314723f42038aab9b54498e588739272b9879b4895&w=826"), MediaURLs(type: "image", url: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")]
    let poi = ResolvedItem(id: "Al-Narjs - Riyadh",
                           title: "Supermarket",
                           subtitle: "Al-Narjs - Riyadh",
                           category: "Cafe", type: .hudhud,
                           coordinate: CLLocationCoordinate2D(latitude: 24.79671388339593, longitude: 46.70810150540095),
                           color: .systemRed,
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"),
                           rating: 2,
                           ratingsCount: 25, mediaURLs: mediaURLs)
    return POIMediaView(item: poi)
}
