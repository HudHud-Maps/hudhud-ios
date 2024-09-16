//
//  UserLoginView.swift
//  HudHud
//
//  Created by Alaa . on 27/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import OSLog
import SwiftUI

// MARK: - UserLoginView

struct UserLoginView: View {

    // MARK: Properties

    @State var loginStore: LoginStore
    @Environment(\.dismiss) var dismiss

    @FocusState private var isFocused: Bool

    // MARK: Content

    var body: some View {
        NavigationStack(path: self.$loginStore.path) {
            VStack(alignment: .leading, spacing: 25) {
                // Back button to dismiss the current view
                Button {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .chevronBackward)
                        .resizable()
                        .frame(width: 12, height: 20)
                        .accentColor(Color.Colors.General._04GreyForLines)
                        .shadow(radius: 26)
                        .accessibilityLabel("Go Back")
                }

                Text("Enter your phone number or email")
                    .hudhudFont(.title)

                HStack {
                    // disply text field for country code only if phone number view selected
                    if self.loginStore.userInput == .phone {
                        FloatingLabelInputField(placeholder: "", inputType: .text(text: Binding(
                            get: {
                                return self.loginStore.countryCode
                            },
                            set: { newValue in
                                self.loginStore.countryCode = newValue
                            }
                        )))
                        .keyboardType(self.keyboardTypeForInput)
                        .frame(width: 50)
                    }
                    // Text field for email or phone number based on user choose
                    FloatingLabelInputField(placeholder: self.placeholderForInput, inputType: .text(text: self.bindingForInput))
                        .textContentType(self.loginStore.userInput == .phone ? .telephoneNumber : .emailAddress)
                        .focused(self.$isFocused)
                        .keyboardType(self.keyboardTypeForInput)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    self.isFocused = false
                                }
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            Spacer()
            HStack(spacing: 15) {
                // Button to toggle between phone and email view
                Button {
                    // Dismiss the keyboard (cause we have 2 type of keyboard)
                    self.isFocused = false
                    // Toggle between phone and email
                    self.loginStore.toggleInputType()
                } label: {
                    Text(self.buttonTitle)
                }
                .buttonStyle(LargeButtonStyle(
                    backgroundColor: Color.Colors.General._03LightGrey.opacity(self.loginStore.isInputEmpty ? 0.5 : 1),
                    foregroundColor: .black
                ))
                // Button to proceed to the next view (OTP view)
                Button {
                    Task {
                        await self.loginStore.login(inputText: self.bindingForInput.wrappedValue)
                    }
                } label: {
                    Text("Next")
                }
                .buttonStyle(LargeButtonStyle(
                    backgroundColor: Color.Colors.General._10GreenMain.opacity(self.loginStore.isInputEmpty ? 0.5 : 1),
                    foregroundColor: .white
                ))
                .disabled(self.loginStore.isInputEmpty)
            }
            .padding(.bottom)
            .padding(.horizontal)
            .navigationDestination(for: LoginStore.UserRegistrationPath.self) { route in
                switch route {
                case .OTPView:
                    OTPVerificationView(loginStore: self.loginStore)
                        .toolbarRole(.editor)
                case .personalInfoView:
                    PersonalInformationScreenView(loginStore: self.loginStore, onDismiss: { self.dismiss() })
                        .toolbarRole(.editor)
                }
            }
        }
    }
}

private extension UserLoginView {

    // Binding for input text based on user input type
    var bindingForInput: Binding<String> {
        switch self.loginStore.userInput {
        case .phone:
            return self.$loginStore.phone
        case .email:
            return self.$loginStore.email
        }
    }

    // Placeholder text for input field based on user input type
    var placeholderForInput: String {
        switch self.loginStore.userInput {
        case .phone:
            return "Enter Phone Number"
        case .email:
            return "Enter Email Address"
        }
    }

    // Title Of the button display the alternative option for the user
    var buttonTitle: String {
        switch self.loginStore.userInput {
        case .phone:
            return "Use Email"
        case .email:
            return "Use Phone"
        }
    }

    // Keyboard type for input field based on user input type
    var keyboardTypeForInput: UIKeyboardType {
        switch self.loginStore.userInput {
        case .phone:
            return .asciiCapableNumberPad
        case .email:
            return .emailAddress
        }
    }
}

#Preview {
    return UserLoginView(loginStore: LoginStore())
}
