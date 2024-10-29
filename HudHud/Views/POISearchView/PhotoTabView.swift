//
//  PhotoTabView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct PhotoTabView: View {

    // MARK: Properties

    let item: ResolvedItem

    @State private var selectedMedia: URL?

    // MARK: Content

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                PhotosView(items: self.item.mediaURLs, id: \.self, spacing: 5) { url in
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            ZStack(alignment: .bottomTrailing) {
                                image
                                    .resizable()
                                    .onTapGesture {
                                        self.selectedMedia = url
                                    }
                                // Display an image label, styled and positioned at bottom-right
                                Text(self.item.title)
                                    .hudhudFontStyle(.labelSmall)
                                    .padding(8)
                                    .background(Color.Colors.General._01Black.opacity(0.5))
                                    .foregroundColor(Color.Colors.General._05WhiteBackground)
                                    .clipShape(.rect(topLeadingRadius: 8))
                            }
                        case .failure:
                            Color.gray
                        case .empty:
                            ProgressView()
                                .cornerRadius(7.0)
                                .progressViewStyle(.automatic)
                                .frame(width: 96, height: 96)
                        @unknown default:
                            Color.gray
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .sheet(item: self.$selectedMedia) { mediaURL in
                FullPageImage(
                    mediaURL: mediaURL,
                    mediaURLs: self.item.mediaURLs
                )
            }
            Button(action: {
                //  add photo
            }, label: {
                ZStack {
                    Circle()
                        .fill(Color.Colors.General._06DarkGreen)
                        .frame(width: 56, height: 56)
                    Image(.addPhoto)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.Colors.General._05WhiteBackground)
                }
            })
            .padding([.bottom, .trailing], 16)
        }
    }
}

#Preview {
    PhotoTabView(item: .artwork)
}
