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

    // MARK: Properties

    var mediaURLs: [URL]

    @State private var selectedMedia: URL?

    // MARK: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.mediaURLs, id: \.self) { mediaURL in
                    AsyncImage(url: mediaURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(.automatic)
                            .frame(width: 96, height: 96)
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
                mediaURLs: self.mediaURLs
            )
        }
    }
}

// MARK: - FullPageImage

struct FullPageImage: View {

    // MARK: Properties

    @State var mediaURL: URL
    let mediaURLs: [URL]
    @Environment(\.dismiss) var dismiss

    // MARK: Content

    var body: some View {
        NavigationStack {
            TabView(selection: self.$mediaURL) {
                ForEach(self.mediaURLs, id: \.self) { mediaURL in
                    AsyncImage(url: mediaURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(.automatic)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(mediaURL)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.dismiss()
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
