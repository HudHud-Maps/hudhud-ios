//
//  AddPhotoConfirmationDialog.swift
//  HudHud
//
//  Created by Fatima Aljaber on 05/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - AddPhotoConfirmationDialog

struct AddPhotoConfirmationDialog: ViewModifier {

    // MARK: Properties

    @Binding var isPresented: Bool
    let onCameraAction: () -> Void
    let onLibraryAction: () -> Void

    // MARK: Content

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Add Photo", isPresented: self.$isPresented) {
                Button("From Camera", action: self.onCameraAction)
                Button("From Library", action: self.onLibraryAction)
                Button("Cancel", role: .cancel) {}
            }
    }
}

extension View {
    func addPhotoConfirmationDialog(isPresented: Binding<Bool>,
                                    onCameraAction: @escaping () -> Void,
                                    onLibraryAction: @escaping () -> Void) -> some View {
        self.modifier(AddPhotoConfirmationDialog(isPresented: isPresented, onCameraAction: onCameraAction, onLibraryAction: onLibraryAction))
    }
}
