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
                CustomOTPTextFieldRepresentable(text: Binding(get: { self.pins[index] },
                                                              set: { newValue in
                                                                  self.pins[index] = String(newValue.prefix(1))
                                                                  self.updateOTP()
                                                                  if !newValue.isEmpty, index < self.numberOfFields - 1 {
                                                                      self.focusedField = index + 1
                                                                  }
                                                              }),
                                                isFocused: Binding(get: { self.focusedField == index },
                                                                   set: { _ in }),
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
                                                allFieldsFilled: self.allFieldsFilled)
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
}

// MARK: - Private

private extension OTPFieldView {

    var allFieldsFilled: Bool {
        self.pins.allSatisfy { !$0.isEmpty }
    }

    func bottomBorder(for index: Int) -> some View {
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

    func handlePasteOrAutofill(_ text: String) {
        let otpDigits = text.filter(\.isNumber).prefix(self.numberOfFields)

        if otpDigits.count == self.numberOfFields {
            for (index, digit) in otpDigits.enumerated() {
                self.pins[index] = String(digit)
            }
            self.updateOTP()
            self.focusedField = self.numberOfFields - 1
        }
    }

    func updateOTP() {
        self.otp = self.pins.joined()
        if self.otp.isEmpty {
            self.hasBeenInvalidated = false
        }
    }
}
