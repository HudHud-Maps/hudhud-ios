//
//  CameraStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 23/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import AVFoundation
import Foundation
import SwiftUI
import UIKit

// MARK: - CameraStore

@Observable
final class CameraStore {

    // MARK: Properties

    var capturedImage: UIImage?
    var isCameraPermissionGranted = false
    var isShowingCamera = false
    var showAlert = false
    var showAddPhotoConfirmation = false

    // MARK: Lifecycle

    init() {
        self.checkCameraPermission()
    }

    // MARK: Functions

    // Request camera permissions
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isCameraPermissionGranted = granted
                }
            }
        case .denied, .restricted:
            self.isCameraPermissionGranted = false
        @unknown default:
            break
        }
    }

    func openCamera() {
        if self.isCameraPermissionGranted {
            self.isShowingCamera = true
        } else {
            self.showAlert = true
        }
    }
}

// MARK: - AccessCameraView

struct AccessCameraView: UIViewControllerRepresentable {

    // MARK: Properties

    var cameraStore: CameraStore
    @Environment(\.presentationMode) var isPresented

    // MARK: Functions

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(cameraStore: self.cameraStore, presentationMode: self.isPresented)
    }
}

// MARK: - Coordinator

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // MARK: Properties

    var cameraStore: CameraStore
    var presentationMode: Binding<PresentationMode>

    // MARK: Lifecycle

    init(cameraStore: CameraStore, presentationMode: Binding<PresentationMode>) {
        self.cameraStore = cameraStore
        self.presentationMode = presentationMode
    }

    // MARK: Functions

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.cameraStore.capturedImage = selectedImage
        self.presentationMode.wrappedValue.dismiss()
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - CameraAccessModifier

struct CameraAccessModifier: ViewModifier {

    // MARK: Properties

    @State var cameraStore: CameraStore
    let onImageCaptured: (UIImage) -> Void

    // MARK: Content

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: self.$cameraStore.isShowingCamera) {
                AccessCameraView(cameraStore: self.cameraStore)
                    .background(.black)
                    .onDisappear {
                        if let image = cameraStore.capturedImage {
                            self.onImageCaptured(image)
                        }
                    }
            }
            .alert(isPresented: self.$cameraStore.showAlert) {
                Alert(
                    title: Text("Camera Access Required"),
                    message: Text("Camera access is required to take photos. Please enable it in Settings > HudHud app > Camera"),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    func withCameraAccess(cameraStore: CameraStore, onImageCaptured: @escaping (UIImage) -> Void) -> some View {
        self.modifier(CameraAccessModifier(cameraStore: cameraStore, onImageCaptured: onImageCaptured))
    }
}
