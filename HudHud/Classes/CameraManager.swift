//
//  CameraManager.swift
//  HudHud
//
//  Created by Fatima Aljaber on 23/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import AVFoundation
import Foundation
import SwiftUI
import UIKit

// MARK: - CameraManager

@Observable
final class CameraManager: NSObject {

    // MARK: Properties

    var capturedImage: UIImage?
    var isCameraPermissionGranted = false
    var isShowingCamera = false
    var showAlert = false

    // MARK: Lifecycle

    override init() {
        super.init()
        self.checkCameraPermission()
    }

    // MARK: Functions

    // Request camera permissions
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
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

    @Binding var selectedImage: UIImage?
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
        return Coordinator(picker: self)
    }
}

// MARK: - Coordinator

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // MARK: Properties

    var picker: AccessCameraView

    // MARK: Lifecycle

    init(picker: AccessCameraView) {
        self.picker = picker
    }

    // MARK: Functions

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        self.picker.isPresented.wrappedValue.dismiss()
    }
}
