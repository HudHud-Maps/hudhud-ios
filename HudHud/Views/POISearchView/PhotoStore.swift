//
//  PhotoStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 05/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import PhotosUI
import SwiftUI

@Observable
final class PhotoStore {

    // MARK: Nested Types

    struct State: Equatable {

        var selectedImages: [UIImage] = []
        var selection: [PhotosPickerItem] = []

    }

    enum Action {
        case addImages([PhotosPickerItem])
        case addImageFromCamera(UIImage)
        case removeImage(UIImage)
        case clearImages
    }

    // MARK: Properties

    var showLibrary = false

    private(set) var state: State

    // MARK: Lifecycle

    init() {
        self.state = State()
    }

    // MARK: Content

    func openPhotosPicker() -> some View {
        PhotosPicker(
            selection: Binding(
                get: { self.state.selection },
                set: { self.reduce(action: .addImages($0)) }
            ),
            matching: .images
        ) {
            VStack {
                Image(.addPhotoLibrary)
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            .padding(24)
            .background(Color.Colors.General._05WhiteBackground)
            .cornerRadius(10)
        }
    }

    // MARK: Functions

    func reduce(action: Action) {
        switch action {
        case let .addImages(images):
            self.addImages(images)

        case let .addImageFromCamera(image):
            self.state.selectedImages.append(image)

        case let .removeImage(image):
            self.state.selectedImages.removeAll { $0 == image }

        case .clearImages:
            self.state.selectedImages.removeAll()
        }
    }

    func addImages(_ images: [PhotosPickerItem]) {
        Task {
            for image in images {
                if let data = try? await image.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    self.state.selectedImages.append(uiImage)
                }
            }
        }
    }

    func addImagesFromCamera(newImage: UIImage) {
        self.state.selectedImages.append(newImage)
    }
}
