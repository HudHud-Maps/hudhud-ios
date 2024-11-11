//
//  WriteReviewView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 20/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import OSLog
import PhotosUI
import SwiftUI
import TypographyKit
import UIKit

// MARK: - WriteReviewView

struct WriteReviewView: View {

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var cameraStore = CameraStore()
    @State var textEditorHeight: CGFloat = 128
    let item: ResolvedItem
    var store: RatingStore
    let sheetStore: SheetStore

    var body: some View {
        VStack {
            self.header
            self.itemRating
            self.reviewTextEditor
            self.photoAndVideoSection
            Spacer()
            self.submitButton
        }
        .background(Color.Colors.General._03LightGrey)
    }

    // MARK: - Header Section

    var header: some View {
        HStack {
            Text("Rate and review")
                .foregroundStyle(Color.Colors.General._01Black)

            Spacer()
            self.closeButton(backgroundColor: Color.Colors.General._03LightGrey, size: 30) {
                self.sheetStore.popSheet()
            }
        }
        .padding()
        .background(Color.Colors.General._05WhiteBackground)
    }

    // MARK: - Item Rating Section

    var itemRating: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(self.item.title)
                    .foregroundStyle(Color.Colors.General._01Black)
                    .hudhudFontStyle(.labelMedium)
                Text(self.item.description)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(1)
                    .hudhudFontStyle(.paragraphSmall)
                StarInteractionView(store: self.store)
                    .padding(.top, 8)
            }
            .padding(16)
            .background(Color.Colors.General._05WhiteBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Review Text Editor Section

    var reviewTextEditor: some View {
        VStack(alignment: .leading) {
            Text("Share your experience")
                .padding(.vertical, 16)
                .hudhudFontStyle(.labelMedium)

            TextEditor(text: Binding(get: { self.store.state.reviewText.isEmpty ? self.store.state.placeholderString : self.store.state.reviewText },
                                     set: { self.store.reduce(action: .updateReviewText($0)) }))
                .frame(height: 128)
                .foregroundStyle(self.store.state.reviewText.isEmpty ? Color.Colors.General._02Grey : Color.Colors.General._01Black)
                .hudhudFontStyle(.paragraphMedium)
                .focused(self.$isFocused)
                .padding([.top, .leading], 8)
                .background(Color.Colors.General._05WhiteBackground)
                .cornerRadius(12)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            self.isFocused = false
                        }
                    }
                }
                .onTapGesture {
                    self.store.reduce(action: .removePlaceHolder)
                }
        }
        .padding(.horizontal)
    }

    // MARK: - Photo & Video Section

    var photoAndVideoSection: some View {
        VStack(alignment: .leading) {
            Text("Add photos and videos")
                .padding(.vertical, 16)
                .hudhudFontStyle(.labelMedium)

            HStack(spacing: 12) {
                Button {
                    self.cameraStore.openCamera()
                } label: {
                    VStack {
                        Image(.addCameraPhoto)
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    .padding(24)
                    .background(Color.Colors.General._05WhiteBackground)
                    .cornerRadius(10)
                }
                .fullScreenCover(isPresented: self.$cameraStore.isShowingCamera) {
                    AccessCameraView(cameraStore: self.cameraStore)
                        .background(.black)
                        .onDisappear {
                            if let image = cameraStore.capturedImage {
                                self.store.addImagesFromCamera(newImage: image)
                            }
                        }
                }
                .alert(isPresented: self.$cameraStore.showAlert) {
                    Alert(title: Text("Camera Access Required"),
                          message: Text("Camera access is required to take photos. Please enable it in Settings > HudHud app > Camera"),
                          dismissButton: .default(Text("OK")))
                }

                PhotosPicker(selection: Binding(get: { self.store.state.selection },
                                                set: { self.store.reduce(action: .addImages($0)) }),
                             matching: .images) {
                    VStack {
                        Image(.addPhotoLibrary)
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    .padding(24)
                    .background(Color.Colors.General._05WhiteBackground)
                    .cornerRadius(10)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(self.store.state.selectedImages, id: \.self) { image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .cornerRadius(10)
                                self.closeButton(backgroundColor: Color.Colors.General._05WhiteBackground, size: 24) {
                                    self.store.reduce(action: .removeImage(image))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Submit Button

    var submitButton: some View {
        Button {
            // action to submit the review
        } label: {
            Text("Submit")
        }
        .disabled(self.store.state.interactiveRating == 0)
        .buttonStyle(LargeButtonStyle(isLoading: .constant(false),
                                      backgroundColor: Color.Colors.General._06DarkGreen.opacity(self.store.state.interactiveRating == 0 ? 0.5 : 1),
                                      foregroundColor: .white))
        .padding(.horizontal)
    }
}

// MARK: - Private

private extension WriteReviewView {

    @ViewBuilder
    func closeButton(backgroundColor: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }, label: {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)

                Image(.closeIcon)
                    .foregroundStyle(Color.Colors.General._01Black)
            }
            .padding(4)
            .contentShape(Circle())
        })
        .tint(.secondary)
        .accessibilityLabel(Text("Close", comment: "accessibility label instead of x"))
    }
}

#Preview {
    WriteReviewView(item: .artwork, store: RatingStore(staticRating: 4.1, ratingsCount: 508, interactiveRating: 0),
                    sheetStore: SheetStore(emptySheetType: .search))
}
