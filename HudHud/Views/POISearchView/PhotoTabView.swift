//
//  PhotoTabView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import NukeUI
import SwiftUI

struct PhotoTabView: View {

    // MARK: Properties

    let item: ResolvedItem

    @Binding var selectedMedia: URL?

    // MARK: Content

    var body: some View {
        PhotosView(items: self.item.mediaURLs, id: \.self, spacing: 5) { url, size in
            LazyImage(url: url) { state in
                ZStack(alignment: .bottomTrailing) {
                    if let image = state.image {
                        // Display the loaded image
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                            .onTapGesture {
                                self.selectedMedia = url
                            }
                        // Display an image label, styled and positioned at bottom-right
                        Text(self.item.title)
                            .hudhudFontStyle(.labelSmall)
                            .padding(8)
                            .frame(width: 80, height: 24)
                            .background(Color.Colors.General._01Black.opacity(0.5))
                            .foregroundColor(Color.Colors.General._05WhiteBackground)
                            .clipShape(.rect(topLeadingRadius: 8))
                    } else if state.isLoading {
                        ProgressView()
                            .cornerRadius(7.0)
                            .progressViewStyle(.automatic)
                            .frame(width: 96, height: 96)
                    } else {
                        Color.gray
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var url = ResolvedItem.artwork.mediaURLs.first
    PhotoTabView(item: .artwork, selectedMedia: $url)
}
