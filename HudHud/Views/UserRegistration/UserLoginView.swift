//
//  UserLoginView.swift
//  HudHud
//
//  Created by Alaa . on 27/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - UserLoginView

struct UserLoginView: View {
    @StateObject private var loginStore = LoginStore()
    @State var title: String = "Sign In"
    @State private var path = NavigationPath()
    var body: some View {
        NavigationStack(path: self.$path) {
            ZStack {
                Image(.loginBackground)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading) {
                    Spacer()

                    Text(self.title)
                        .hudhudFont(.title)

                    FloatingLabelInputField(placeholder: self.placeholderForInput, inputType: .text(text: self.bindingForInput))
                        .padding(.top)
                        .keyboardType(self.keyboardTypeForInput)

                    Spacer()

                    Button {
                        self.path.append(LoginStore.UserRegistrationPath.OTPView)
                    } label: {
                        Text(self.title)
                    }
                    .buttonStyle(LargeButtonStyle(
                        backgroundColor: Color.Colors.General._07BlueMain.opacity(self.loginStore.isInputEmpty ? 0.5 : 1),
                        foregroundColor: .white
                    ))
                    .disabled(self.loginStore.isInputEmpty)

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationDestination(for: LoginStore.UserRegistrationPath.self) { route in
                switch route {
                case .OTPView:
                    OTPVerificationView(phoneNumber: self.bindingForInput.wrappedValue, path: self.$path)
                        .toolbarRole(.editor)
                case .personalInfoView:
                    PersonalInformationScreenView(path: self.$path)
                        .toolbarRole(.editor)
                }
            }
        }
    }
}

private extension UserLoginView {
    var bindingForInput: Binding<String> {
        switch self.loginStore.userInput {
        case .phone:
            return self.$loginStore.phone
        case .email:
            return self.$loginStore.email
        }
    }

    var placeholderForInput: String {
        switch self.loginStore.userInput {
        case .phone:
            return "Phone Number"
        case .email:
            return "Email Address"
        }
    }

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
    UserLoginView()
}
