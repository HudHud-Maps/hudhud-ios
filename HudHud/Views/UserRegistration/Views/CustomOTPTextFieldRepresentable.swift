//
//  CustomOTPTextFieldRepresentable.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct CustomOTPTextFieldRepresentable: UIViewRepresentable {

    // MARK: Nested Types

    final class Coordinator: NSObject, UITextFieldDelegate {

        // MARK: Properties

        var parent: CustomOTPTextFieldRepresentable

        // MARK: Lifecycle

        init(_ parent: CustomOTPTextFieldRepresentable) {
            self.parent = parent
        }

        // MARK: Functions

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
            self.parent.text = String(updatedText.prefix(1))
            return false
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if self.parent.isLastField, self.parent.allFieldsFilled {
                (gesture.view as? UITextField)?.becomeFirstResponder()
            }
        }
    }

    // MARK: Properties

    @Binding var text: String
    @Binding var isFocused: Bool
    var onBackspace: () -> Void
    var onPasteOrAutofill: (String) -> Void
    var isLastField: Bool
    var allFieldsFilled: Bool

    // MARK: Functions

    func makeUIView(context: Context) -> CustomOTPTextField {
        let textField = CustomOTPTextField()
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = .hudhudFont(.title3)
        textField.textColor = .black
        textField.onBackspace = self.onBackspace
        textField.isLastField = self.isLastField
        textField.onPasteOrAutofill = self.onPasteOrAutofill
        textField.textContentType = .oneTimeCode

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        textField.addGestureRecognizer(tapGesture)

        return textField
    }

    func updateUIView(_ uiView: CustomOTPTextField, context _: Context) {
        uiView.text = self.text
        uiView.allFieldsFilled = self.allFieldsFilled
        if self.isFocused {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
