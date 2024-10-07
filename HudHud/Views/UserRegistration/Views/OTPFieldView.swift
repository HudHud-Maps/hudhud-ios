//
//  OTPFieldView.swift
//  HudHud
//
//  Created by Ali Hilal on 06/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - OTPFieldView

struct OTPFieldView: View {

    // MARK: Properties

    @Binding var otp: String
    @Binding var isValid: Bool

    @State private var hasBeenInvalidated: Bool = false
    @State private var pins: [String]

    @FocusState private var focusedField: Int?

    private let numberOfFields: Int = 6

    // MARK: Computed Properties

    private var allFieldsFilled: Bool {
        self.pins.allSatisfy { !$0.isEmpty }
    }

    // MARK: Lifecycle

    init(otp: Binding<String>, isValid: Binding<Bool>) {
        self._otp = otp
        self._isValid = isValid
        self._pins = State(initialValue: Array(repeating: "", count: self.numberOfFields))
    }

    // MARK: Content

    var body: some View {
        HStack(spacing: 15) {
            ForEach(0 ..< self.numberOfFields, id: \.self) { index in
                CustomOTPTextFieldRepresentable(
                    text: Binding(
                        get: { self.pins[index] },
                        set: { newValue in
                            self.pins[index] = String(newValue.prefix(1))
                            self.updateOTP()
                            if !newValue.isEmpty, index < self.numberOfFields - 1 {
                                self.focusedField = index + 1
                            }
                        }
                    ),
                    isFocused: Binding(
                        get: { self.focusedField == index },
                        set: { _ in }
                    ),
                    onBackspace: {
                        if index > 0 {
                            self.pins[index - 1] = ""
                            self.updateOTP()
                            self.focusedField = index - 1
                        }
                    },
                    onPasteOrAutofill: { text in
                        self.handlePasteOrAutofill(text)
                    },
                    isLastField: index == self.numberOfFields - 1,
                    allFieldsFilled: self.allFieldsFilled
                )
                .frame(width: 40, height: 50)
                .background(self.bottomBorder(for: index), alignment: .bottom)
                .focused(self.$focusedField, equals: index)
                .textContentType(.oneTimeCode)
            }
        }
        .onAppear {
            self.pins = Array(self.otp.prefix(6)).map(String.init) + Array(repeating: "", count: max(0, 6 - self.otp.count))
            self.focusedField = self.pins.firstIndex(where: { $0.isEmpty }) ?? 5
        }
        .onChange(of: self.otp) { _, newValue in
            self.pins = Array(newValue.prefix(6)).map(String.init) + Array(repeating: "", count: max(0, 6 - newValue.count))
        }
        .onChange(of: self.isValid) { _, newValue in
            if !newValue {
                self.hasBeenInvalidated = true
            }
        }
    }

    private func bottomBorder(for index: Int) -> some View {
        var color: Color {
            if !self.isValid, self.hasBeenInvalidated {
                return Color.Colors.General._12Red
            } else if self.focusedField == index {
                return Color.Colors.General._10GreenMain
            } else {
                return Color.Colors.General._04GreyForLines
            }
        }

        return Rectangle()
            .frame(height: 2)
            .foregroundColor(color)
            .padding(.top, 8)
    }

    // MARK: Functions

    private func handlePasteOrAutofill(_ text: String) {
        let otpDigits = text.filter(\.isNumber).prefix(self.numberOfFields)

        if otpDigits.count == self.numberOfFields {
            for (index, digit) in otpDigits.enumerated() {
                self.pins[index] = String(digit)
            }
            self.updateOTP()
            self.focusedField = self.numberOfFields - 1
        }
    }

    private func updateOTP() {
        self.otp = self.pins.joined()
        if self.otp.isEmpty {
            self.hasBeenInvalidated = false
        }
    }
}

// MARK: - CustomOTPTextFieldRepresentable

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

// MARK: - CustomOTPTextField

final class CustomOTPTextField: UITextField {

    // MARK: Overridden Properties

    override var selectedTextRange: UITextRange? {
        get {
            if self.isLastField, self.allFieldsFilled {
                return super.selectedTextRange
            }
            return nil
        }
        set {
            if self.isLastField, self.allFieldsFilled {
                super.selectedTextRange = newValue
            }
        }
    }

    // MARK: Properties

    var onBackspace: (() -> Void)?
    var onPasteOrAutofill: ((String) -> Void)?
    var isLastField: Bool = false
    var allFieldsFilled: Bool = false

    // MARK: Overridden Functions

    override func deleteBackward() {
        if let onBackspace, text?.isEmpty ?? true {
            onBackspace()
        }
        super.deleteBackward()
    }

    override func canPerformAction(_ action: Selector, withSender _: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return true
        }
        if self.isLastField, self.allFieldsFilled {
            return action == #selector(UIResponderStandardEditActions.copy(_:))
        }
        return false
    }

    override func paste(_: Any?) {
        if let pasteboardString = UIPasteboard.general.string {
            self.onPasteOrAutofill?(pasteboardString)
        }
    }

    override func insertText(_ text: String) {
        if text.count > 1 {
            self.onPasteOrAutofill?(text)
        } else {
            super.insertText(text)
        }
    }

    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        if self.isLastField, self.allFieldsFilled {
            return super.closestPosition(to: point)
        }
        return endOfDocument
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        if self.isLastField, self.allFieldsFilled {
            return super.caretRect(for: position)
        }
        return .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        if self.isLastField, self.allFieldsFilled {
            return super.selectionRects(for: range)
        }
        return []
    }

    override func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        if self.isLastField, self.allFieldsFilled {
            return super.position(from: position, offset: offset)
        }
        return endOfDocument
    }

    override func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        if self.isLastField, self.allFieldsFilled {
            return super.position(from: position, in: direction, offset: offset)
        }
        return endOfDocument
    }

    override func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        if self.isLastField, self.allFieldsFilled {
            return super.textRange(from: fromPosition, to: toPosition)
        }
        let endPosition = self.position(from: endOfDocument, offset: 0) ?? endOfDocument
        return super.textRange(from: endPosition, to: endPosition)
    }
}
