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
        self._store = State(initialValue: OTPVerificationStore(loginId: loginId, duration: duration, loginIdentity: loginIdentity))
        self._path = path
        self.loginStore = loginStore
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

            VStack {
                HStack(spacing: 10) {
                    ForEach(0 ..< 6, id: \.self) { index in
                        TextField("", text: self.$store.code[index])
                            .focused(self.$focusedIndex, equals: index)
                            .keyboardType(.asciiCapableNumberPad)
                            .textContentType(.oneTimeCode)
                            .scrollDismissesKeyboard(.interactively)
                            .multilineTextAlignment(.center)
                            .frame(height: 50)
                            .hudhudFont(.title3)
                            .background(self.bottomBorder(for: index), alignment: .bottom)
                            .onChange(of: self.store.code[index]) { oldCode, newCode in
                                self.handleCode(oldCode, newCode, at: index)
                            }
                            .onSubmit {
                                if index == 5, self.store.isCodeComplete {
                                    Task {
                                        await self.store.verifyOTP()
                                    }
                                }
                            }
                    }
                }
                .padding()
                .onAppear {
                    self.focusedIndex = 0
                }
            }
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
                .buttonStyle(LargeButtonStyle(
                    backgroundColor: Color.Colors.General._10GreenMain.opacity(!self.store.isCodeComplete ? 0.5 : 1),
                    foregroundColor: .white
                ))
                .disabled(!self.store.isCodeComplete || self.store.isLoading)
            }
            .padding()
            .onAppear {
                self.store.startTimer()
            }
            .onDisappear {
                self.store.timer?.invalidate()
            }
            .onChange(of: self.store.isCodeComplete) { _, _ in
                if self.store.isCodeComplete {
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

    // One line under each TextField
    private func bottomBorder(for index: Int) -> some View {
        Rectangle()
            .frame(height: 2)
            .foregroundColor(self.store.errorMessage != nil ? Color.Colors.General._12Red :
                (self.focusedIndex == index ? Color.Colors.General._10GreenMain : Color.Colors.General._04GreyForLines))
            .padding(.top, 8)
    }

    // MARK: Functions

    private func handleCode(_ oldCode: String, _ newCode: String, at index: Int) {
        var cleanedCode = newCode

        if newCode.count > oldCode.count {
            let newCharacter = newCode.filter { !oldCode.contains($0) }
            cleanedCode = String(newCharacter)
        }

        self.store.code[index] = cleanedCode

        if !cleanedCode.isEmpty, index < 5 {
            self.focusedIndex = index + 1
        } else if cleanedCode.isEmpty, index > 0 {
            self.focusedIndex = index - 1
        }

        if self.store.isCodeComplete {
            self.focusedIndex = nil
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    let loginStore = LoginStore()
    return OTPVerificationView(loginId: UUID().uuidString, loginIdentity: "+966503539560", duration: .now, path: $path, loginStore: loginStore)
}
