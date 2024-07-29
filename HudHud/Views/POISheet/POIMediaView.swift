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
    var mediaURLs: [URL]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.mediaURLs, id: \.self) { mediaURL in
                    AsyncImage(url: mediaURL) { image in
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
        .scrollIndicators(.hidden)
    }
}

#Preview {
    return POIMediaView(mediaURLs: .mediaURLs)
}
