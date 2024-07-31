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

// MARK: - POIMediaView

struct POIMediaView: View {
    var mediaURLs: [URL]
    @State private var selectedMedia: URL?

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
                    .onTapGesture {
                        self.selectedMedia = mediaURL
                    }
                }
            }
            .padding(.leading)
        }
        .scrollIndicators(.hidden)
        .sheet(item: self.$selectedMedia) { mediaURL in
            FullPageImage(
                mediaURL: mediaURL,
                selectedMediaURL: self.$selectedMedia
            )
        }
    }
}

// MARK: - FullPageImage

struct FullPageImage: View {
    let mediaURL: URL
    @Binding var selectedMediaURL: URL?

    var body: some View {
        NavigationStack {
            AsyncImage(url: self.mediaURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
                    .progressViewStyle(.automatic)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.selectedMediaURL = nil
                    } label: {
                        Image(systemSymbol: .xCircleFill)
                            .tint(.gray)
                    }
                }
            }
        }
    }
}

#Preview {
    return POIMediaView(mediaURLs: .previewMediaURLs)
}
