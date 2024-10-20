//
//  PhotoSectionView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 16/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct PhotoSectionView: View {

    // MARK: Properties

    let item: ResolvedItem

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            Text("Photos")
                .font(.headline)
                .foregroundColor(Color.Colors.General._01Black)
                .padding(.leading)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(0 ..< min(self.item.mediaURLs.count, 6), id: \.self) { index in
                        if index % 3 == 0 {
                            VStack(spacing: 10) {
                                // Small Images
                                if index < self.item.mediaURLs.count {
                                    self.imageView(for: self.item.mediaURLs[index], size: CGSize(width: 120, height: 120))
                                }
                                if index + 1 < self.item.mediaURLs.count {
                                    self.imageView(for: self.item.mediaURLs[index + 1], size: CGSize(width: 120, height: 120))
                                }
                            }
                            // Big Image
                            if index + 2 < self.item.mediaURLs.count {
                                self.imageView(for: self.item.mediaURLs[index + 2], size: CGSize(width: 175, height: 248))
                            }
                        }
                    }

                    // Buttons for "View All" and "Add Photo"
                    VStack {
                        // if the images more than 6 we show view all button
                        if self.item.mediaURLs.count > 6 {
                            self.actionButton(title: "View All", imageName: "photoLibrary") {
                                // Action for View All
                            }
                        }
                        self.actionButton(title: "Add Photo", imageName: "addPhoto") {
                            // Action for Add Photo
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private func imageView(for url: URL, size: CGSize) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .cornerRadius(10)
        } placeholder: {
            ProgressView()
                .progressViewStyle(.automatic)
                .frame(width: size.width, height: size.height)
                .background(.secondary)
                .cornerRadius(7.0)
        }
    }

    @ViewBuilder
    private func actionButton(title: String, imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(imageName)
                    .resizable()
                    .frame(width: 25, height: 25)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.Colors.General._06DarkGreen)
            }
            .frame(width: 120, height: 120)
            .background(Color.Colors.General._11GreenLight)
            .cornerRadius(10)
        }
    }
}

#Preview {
    PhotoSectionView(item: .artwork)
}
