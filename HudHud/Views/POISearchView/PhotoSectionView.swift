//
//  PhotoSectionView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 16/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import NukeUI
import OSLog
import SwiftUI

struct PhotoSectionView: View {

    // MARK: Nested Types

    enum ImageSizes {
        static let small = CGSize(width: 120, height: 120)
        static let medium = CGSize(width: 175, height: 248)
        static let large = CGSize(width: 248, height: 248)
    }

    // MARK: Properties

    let item: ResolvedItem

    @State private var selectedMedia: URL?
    @Binding var selectedTab: POIOverviewView.Tab
    @Bindable var photoStore: PhotoStore
    @Bindable var cameraStore: CameraStore

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            Text("Photos")
                .hudhudFontStyle(.labelMedium)
                .foregroundColor(Color.Colors.General._01Black)

            if self.item.mediaURLs.isEmpty {
                self.noImagesView()
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .center, spacing: 10) {
                        switch self.item.mediaURLs.count {
                        case 5...:
                            self.displayFiveImages()
                        case 4:
                            self.displayFourImages()
                        case 3:
                            self.displayThreeImages()
                        case 2:
                            self.displayTwoImages()
                        case 1:
                            self.displayOneImage()
                        default:
                            EmptyView()
                        }

                        self.actionButtonsView()
                    }
                }
                .scrollIndicators(.hidden)
            }
        }.padding()
            .addPhotoConfirmationDialog(isPresented: self.$cameraStore.showAddPhotoConfirmation, onCameraAction: {
                self.cameraStore.openCamera()
            }, onLibraryAction: {
                self.photoStore.openLibrary()
            })
            .withCameraAccess(cameraStore: self.cameraStore) { capturedImage in
                self.photoStore.reduce(action: .addImageFromCamera(capturedImage))
            }
            .photosPicker(isPresented: self.$photoStore.showLibrary, selection: Binding(
                get: { self.photoStore.state.selection },
                set: { self.photoStore.reduce(action: .addImages($0)) }
            ))
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func noImagesView() -> some View {
        Text("There is no photo added yet! Be the first to add one.")
            .hudhudFontStyle(.labelXxsmall)
            .foregroundColor(Color.Colors.General._02Grey)

        HStack {
            Spacer()
            self.actionButton(title: "Add Photo", imageName: "addPhoto", isSmallButton: true) {
                // Action for Add Photo
            }
            Spacer()
        }
        .padding(.vertical, 30)
    }

    // MARK: - Image Display Functions

    @ViewBuilder
    private func displayFiveImages() -> some View {
        VStack(spacing: 10) {
            self.imageView(for: self.item.mediaURLs[0], label: self.item.title, size: ImageSizes.small)

            self.imageView(for: self.item.mediaURLs[1], label: self.item.title, size: ImageSizes.small)
        }

        self.imageView(for: self.item.mediaURLs[2], label: self.item.title, size: ImageSizes.large)

        VStack(spacing: 10) {
            self.imageView(for: self.item.mediaURLs[3], label: self.item.title, size: ImageSizes.small)

            self.imageView(for: self.item.mediaURLs[4], label: self.item.title, size: ImageSizes.small)
        }
    }

    @ViewBuilder
    private func displayFourImages() -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                self.imageView(for: self.item.mediaURLs[0], label: self.item.title, size: ImageSizes.small)
                self.imageView(for: self.item.mediaURLs[1], label: self.item.title, size: ImageSizes.small)
            }

            HStack(spacing: 10) {
                self.imageView(for: self.item.mediaURLs[2], label: self.item.title, size: ImageSizes.small)
                self.imageView(for: self.item.mediaURLs[3], label: self.item.title, size: ImageSizes.small)
            }
        }
    }

    @ViewBuilder
    private func displayThreeImages() -> some View {
        VStack(spacing: 10) {
            self.imageView(for: self.item.mediaURLs[0], label: self.item.title, size: ImageSizes.small)
            self.imageView(for: self.item.mediaURLs[1], label: self.item.title, size: ImageSizes.small)
        }
        self.imageView(for: self.item.mediaURLs[2], label: self.item.title, size: ImageSizes.medium)
    }

    @ViewBuilder
    private func displayTwoImages() -> some View {
        ForEach(0 ..< 2, id: \.self) { index in
            self.imageView(for: self.item.mediaURLs[index], label: self.item.title, size: ImageSizes.medium)
        }
    }

    @ViewBuilder
    private func displayOneImage() -> some View {
        self.imageView(for: self.item.mediaURLs[0], label: self.item.title, size: ImageSizes.large)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtonsView() -> some View {
        VStack(alignment: .center) {
            if self.item.mediaURLs.count >= 5 {
                self.actionButton(title: "View All", imageName: "photoLibrary", isSmallButton: true) {
                    // Action for View All
                    self.selectedTab = .photos
                }
            }
            self.actionButton(title: "Add Photo", imageName: "addPhoto", isSmallButton: self.item.mediaURLs.count > 5 ? true : false) {
                // Action for add Photo
                self.cameraStore.showAddPhotoConfirmation.toggle()
            }
        }
    }

    // MARK: - Image View

    @ViewBuilder
    private func imageView(for url: URL, label: String, size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            LazyImage(url: url) { state in
                ZStack(alignment: .bottomTrailing) {
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                            .cornerRadius(15)
                            .onTapGesture {
                                self.selectedMedia = url
                            }
                        // Display an image label, styled and positioned at bottom-right
                        Text(label)
                            .hudhudFontStyle(.labelSmall)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(width: 80, height: 24)
                            .background(Color.Colors.General._01Black.opacity(0.5))
                            .foregroundColor(Color.Colors.General._05WhiteBackground)
                            .clipShape(.rect(topLeadingRadius: 8, bottomTrailingRadius: 15))
                    } else if state.isLoading {
                        ProgressView()
                            .progressViewStyle(.automatic)
                            .frame(width: size.width, height: size.height)
                            .background(Color.Colors.General._03LightGrey)
                            .cornerRadius(7.0)
                    }
                }
            }
        }
        .sheet(item: self.$selectedMedia) { mediaURL in
            FullPageImage(
                mediaURL: mediaURL,
                mediaURLs: self.item.mediaURLs
            )
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private func actionButton(title: String, imageName: String, isSmallButton: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }, label: {
            VStack(spacing: 8) {
                Image(imageName)
                    .resizable()
                    .frame(width: 25, height: 25)
                Text(title)
                    .hudhudFontStyle(.labelSmall)
                    .foregroundColor(Color.Colors.General._06DarkGreen)
            }
            .frame(width: 120, height: isSmallButton ? 120 : 248)
            .background(Color.Colors.General._11GreenLight)
            .cornerRadius(12)
        })
    }
}

#Preview {
    @Previewable @State var about: POIOverviewView.Tab = .about

    PhotoSectionView(item: .artwork,
                     selectedTab: $about, photoStore: .init(), cameraStore: .init())
}
