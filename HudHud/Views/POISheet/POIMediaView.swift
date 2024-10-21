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
        .fullScreenCover(item: self.$selectedMedia) { mediaURL in
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
    @State var actionSheetShown: Bool = false
    @State var isBackendReady: Bool = false

    // MARK: Content

    var body: some View {
        NavigationStack {
            ZStack {
                // blur background
                AsyncImage(url: self.mediaURL) { image in
                    image
                        .resizable()
                        .blur(radius: 20, opaque: true)
                        .overlay(Color.black.opacity(0.6))
                        .ignoresSafeArea()
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.automatic)
                }

                // Main content
                VStack {
                    TabView(selection: self.$mediaURL) {
                        ForEach(self.mediaURLs, id: \.self) { mediaURL in
                            VStack(spacing: 0.0) {
                                AsyncImage(url: mediaURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } placeholder: {
                                    ProgressView()
                                        .progressViewStyle(.automatic)
                                }
                                .tag(mediaURL)

                                Spacer()
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack {
                        HStack {
                            if self.isBackendReady {
                                Image(systemSymbol: .personCircleFill)
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                VStack(alignment: .leading) {
                                    Text("Patrick")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                    Text("12 September 2024")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Button {
                                self.actionSheetShown = true
                            } label: {
                                Image(systemSymbol: .ellipsis)
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }

                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            self.dismiss()
                        } label: {
                            Text("Close")
                                .hudhudFont()
                                .tint(.white)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        if let index = mediaURLs.firstIndex(of: mediaURL) {
                            Text("\(index + 1) of \(self.mediaURLs.count)")
                                .hudhudFont()
                                .foregroundColor(.white)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemSymbol: .cameraFill)
                            .foregroundStyle(Color.Colors.General._06DarkGreen)
                    }
                }
                .confirmationDialog("action", isPresented: self.$actionSheetShown) {
                    Button("Share") {}
                    Button("Report", role: .destructive) {}
                }
            }
        }
    }
}

#Preview {
    return POIMediaView(mediaURLs: .previewMediaURLs)
}
