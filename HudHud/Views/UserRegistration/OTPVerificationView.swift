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

    @State private var store: OTPVerificationStore
    @FocusState private var focusedIndex: Int?

    // MARK: Lifecycle

    // MARK: Initialization

    init(loginId: String, loginIdentity: String, duration: Date, path: Binding<NavigationPath>) {
        self._store = State(initialValue: OTPVerificationStore(loginId: loginId, duration: duration, loginIdentity: loginIdentity))
        self._path = path
    }

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 13) {
                    Text("Enter your Verification Code")
                        .hudhudFont(.title2)
                        .foregroundColor(Color.Colors.General._01Black)
                    Text("We sent verification code on \(self.store.loginIdentity)")
                        .foregroundColor(Color.Colors.General._02Grey)
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
                            .onChange(of: self.store.code[index]) { _, newCode in
                                self.handleCode(newCode, at: index)
                            }
                            .onSubmit {
                                if index == 5, self.store.isCodeComplete {
                                    Task {
                                        await self.store.verifyOTPIfComplete()
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
                    .font(.body)
                    .padding(10)
            }

            Spacer()
            VStack(alignment: .center, spacing: 10) {
                Text("Didn't Get the Code?")
                Button(action: {
                    // Logic to resend OTP
                }, label: {
                    Text("Resend Code \(!self.store.resendEnabled ? "(\(self.store.formattedTime))" : "")")
                        .foregroundColor(self.store.resendEnabled ? Color.Colors.General._10GreenMain : Color.Colors.General._02Grey)
                        .cornerRadius(8)
                })
                .disabled(!self.store.resendEnabled)
                .padding(.bottom)
                Button {
                    Task {
                        await self.store.verifyOTPIfComplete()
                    }
                } label: {
                    if self.store.isLoading {
                        ProgressView()
                    } else {
                        Text("Verify")
                    }
                }
                .buttonStyle(LargeButtonStyle(
                    backgroundColor: Color.Colors.General._07BlueMain.opacity(!self.store.isCodeComplete ? 0.5 : 1),
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
                        await self.store.verifyOTPIfComplete()
                    }
                }
            }
        }
    }

    // One line under each TextField
    private func bottomBorder(for index: Int) -> some View {
        Rectangle()
            .frame(height: 2)
            .foregroundColor(self.focusedIndex == index ? Color.Colors.General._07BlueMain : Color.Colors.General._04GreyForLines)
            .padding(.top, 8)
    }

    // MARK: Functions

    private func handleCode(_ newCode: String, at index: Int) {
        // Check if the filtered digits count exactly 6 digits ..it mean the new code is from SMS message
        if newCode.count == 6 {
            // Assign each digit to the code array
            for (i, digit) in newCode.enumerated() {
                self.store.code[i] = String(digit)
            }
            // Clear focus from all text fields and the keyboard will be dismissed
            self.focusedIndex = nil
        } else {
            if newCode.isEmpty {
                if index > 0 {
                    self.focusedIndex = index - 1
                }
            } else {
                // Update the code with the digits entered
                self.store.code[index] = newCode
                // If the user entered more than 1 digit..remove the first one
                if newCode.count > 1 {
                    self.store.code[index].removeFirst()
                } else {
                    if newCode.isEmpty {
                        if index > 0 {
                            self.focusedIndex = index - 1
                        }
                    } else if index < 5 {
                        self.focusedIndex = index + 1
                    }
                }
                // If the code is complete.. clear focus from all fields and the keyboard will be dismissed
                self.focusedIndex = self.store.isCodeComplete ? nil : index
            }
        }
    }

}

#Preview {
    @State var path = NavigationPath()
    return OTPVerificationView(loginId: UUID().uuidString, loginIdentity: "+966503539560", duration: .now, path: $path)
}
