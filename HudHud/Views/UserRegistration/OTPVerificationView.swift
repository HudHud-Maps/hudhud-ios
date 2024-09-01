//
//  OTPVerificationView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 29/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import OSLog
import SwiftUI

struct OTPVerificationView: View {

    // MARK: Properties

    private var phoneNumber: String
    @State private var timeRemaining: Int = 60
    @State private var resendEnabled: Bool = false
    @State private var timer: Timer?
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?

    // MARK: Computed Properties

    private var isCodeComplete: Bool {
        return self.code.allSatisfy { $0.count == 1 }
    }

    private var formattedTime: String {
        let minutes = self.timeRemaining / 60
        let seconds = self.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: Lifecycle

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 13) {
                    Text("Enter your Verification Code")
                        .hudhudFont(.title2)
                        .foregroundColor(Color.Colors.General._01Black)
                    HStack {
                        Text("We sent verification code on")
                        Text("\(self.phoneNumber)")
                    }
                    .foregroundColor(Color.Colors.General._02Grey)
                }
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.leading)

            VStack {
                HStack(spacing: 10) {
                    ForEach(0 ..< 6, id: \.self) { index in
                        TextField("", text: self.$code[index])
                            .focused(self.$focusedIndex, equals: index)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .scrollDismissesKeyboard(.interactively)
                            .multilineTextAlignment(.center)
                            .frame(width: 40, height: 50)
                            .hudhudFont(.title3)
                            .background(self.bottomBorder(for: index), alignment: .bottom)
                            .onChange(of: self.code[index]) { newCode in
                                self.handleCode(newCode, at: index)
                            }
                    }
                }
                .onAppear {
                    self.focusedIndex = 0
                }
            }
            .padding(.top, 50)

            Spacer()
            VStack(alignment: .center, spacing: 10) {
                Text("Didn't Get the Code?")
                Button(action: {
                    // Currently only reset the timer but it should also send new code to the user
                    self.resetTimer()
                }) {
                    Text("Resend Code \(!self.resendEnabled ? "(\(self.formattedTime))" : "")")
                        .foregroundColor(self.resendEnabled ? Color.Colors.General._10GreenMain : Color.Colors.General._02Grey)
                        .cornerRadius(8)
                }
                .disabled(!self.resendEnabled)
                .padding(.bottom)
                Button(action: {
                    // The fullCode will be send to the backend
                    if self.isCodeComplete {
                        let fullCode = self.code.joined()
                        Logger.userRegistration.info("Code is valid: \(fullCode)")
                    }
                }, label: {
                    Text("Verify")
                })
                .buttonStyle(LargeButtonStyle(
                    backgroundColor: Color.Colors.General._07BlueMain.opacity(!self.isCodeComplete ? 0.5 : 1),
                    foregroundColor: .white
                ))
                .disabled(!self.isCodeComplete)
            }
            .padding()
            .onAppear {
                self.startTimer()
            }
            .onDisappear {
                self.timer?.invalidate()
            }
        }
    }

    // One line under each TextField
    private func bottomBorder(for index: Int) -> some View { Rectangle()
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
                self.code[i] = String(digit)
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
                self.code[index] = newCode
                // If the user entered more than 1 digit..remove the first one
                if newCode.count > 1 {
                    self.code[index].removeFirst()
                } else {
                    if newCode.isEmpty {
                        // If empty and not the first index.. move focus back to the previous field
                        // when user press delete in the keyboard the focusedIndex will move back.
                        if index > 0 {
                            self.focusedIndex = index - 1
                        }
                    } else if index < 5 {
                        // If the user entered number and not the last field.. move focusedIndex to the next field
                        self.focusedIndex = index + 1
                    }
                }
                // If the code is complete.. clear focus from all fields and the keyboard will be dismissed
                // Otherwise, focus on the current index
                self.focusedIndex = self.isCodeComplete ? nil : index
            }
        }
    }

    // set a timer for resend code at one minutes
    private func startTimer() {
        self.resendEnabled = false
        self.timeRemaining = 60

        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.resendEnabled = true
            }
        }
    }

    private func resetTimer() {
        self.timer?.invalidate()
        self.startTimer()
    }
}

#Preview {
    return OTPVerificationView(phoneNumber: "0504325432")
}
