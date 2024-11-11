//
//  OTPVerificationView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 29/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import OSLog
import SwiftUI

struct OTPVerificationView: View {

    // MARK: Properties

    @Binding var path: NavigationPath

    @Environment(\.dismiss) var dismiss

    @State private var store: OTPVerificationStore
    @FocusState private var focusedIndex: Int?
    private let loginStore: LoginStore

    // MARK: Lifecycle

    // MARK: Initialization

    init(loginId: String, loginIdentity: String, duration: Date, path: Binding<NavigationPath>, loginStore: LoginStore) {
        self._path = path
        self.loginStore = loginStore
        self._store = State(initialValue: OTPVerificationStore(loginId: loginId, duration: duration, loginIdentity: loginIdentity))
    }

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 13) {
                    Text("Enter your Verification Code")
                        .hudhudFont(.title2)
                        .foregroundColor(Color.Colors.General._01Black)
                    Text("Verification code sent to the \(self.loginStore.userInput == .phone ? "phone" : "email") below:")
                        .hudhudFont()
                        .foregroundStyle(Color.Colors.General._02Grey)
                    HStack {
                        Text(" \(self.store.loginIdentity)")
                            .foregroundColor(Color.Colors.General._02Grey)
                        Button {
                            self.path.removeLast()
                        } label: {
                            Text("Edit")
                                .hudhudFont()
                                .foregroundStyle(Color.Colors.General._10GreenMain)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.leading)

            OTPFieldView(otp: self.$store.otp, isValid: self.$store.isValid)
                .padding(.top, 50)

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .hudhudFont()
                    .padding(10)
            }

            Spacer()
            VStack(alignment: .center, spacing: 10) {
                Text("Didn't Get the Code?")
                Button(action: {
                    // Logic to resend OTP
                    Task {
                        await self.store.resendOTP(loginId: self.store.loginId)
                    }
                    self.store.startTimer()
                }, label: {
                    Text("Resend Code \(!self.store.resendEnabled ? "(\(self.store.formattedTime))" : "")")
                        .foregroundColor(self.store.resendEnabled ? Color.Colors.General._10GreenMain : Color.Colors.General._02Grey)
                        .cornerRadius(8)
                })
                .disabled(!self.store.resendEnabled)
                .padding(.bottom)
                Button {
                    Task {
                        await self.store.verifyOTP()
                    }
                } label: {
                    if self.store.isLoading {
                        ProgressView()
                        Text("Verify")
                    } else {
                        Text("Verify")
                    }
                }
                .buttonStyle(LargeButtonStyle(isLoading: .constant(false),
                                              backgroundColor: Color.Colors.General._10GreenMain
                                                  .opacity(!self.store.isCodeComplete ? 0.5 : 1),
                                              foregroundColor: .white))
                .disabled(!self.store.isCodeComplete || self.store.isLoading)
            }
            .padding()
            .onAppear {
                self.store.startTimer()
            }
            .onDisappear {
                self.store.timer?.invalidate()
            }
            .onChange(of: self.store.otp) { _, newValue in
                if newValue.count == 6 {
                    Task {
                        await self.store.verifyOTP()
                        if self.store.userLoggedIn {
                            self.loginStore.userLoggedIn = true
                            self.dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    let loginStore = LoginStore()
    return OTPVerificationView(loginId: UUID().uuidString, loginIdentity: "+966503539560", duration: .now, path: $path, loginStore: loginStore)
}
