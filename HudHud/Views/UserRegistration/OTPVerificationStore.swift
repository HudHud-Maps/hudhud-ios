//
//  OTPVerificationStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 01/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
import BackendService
import Combine
import Foundation
import OSLog

@Observable
final class OTPVerificationStore {

    // MARK: Properties

    var loginId: String
    var timer: Timer?
    let loginIdentity: String
    var resendEnabled: Bool = false
    var errorMessage: String?
    var verificationSuccessful: Bool = false
    var isLoading: Bool = false
    var userLoggedIn: Bool = false
    var isValid: Bool = true

    private var registrationService = RegistrationService()

    private var timeRemaining: Int = 60
    private var duration: Date

    // MARK: Computed Properties

    var otp: String = "" {
        didSet {
            self.resetValidity()
        }
    }

    var isCodeComplete: Bool {
        return self.otp.count == 6
    }

    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad // 00:00
        formatter.unitsStyle = .positional
        let formattedString = formatter.string(from: TimeInterval(self.timeRemaining))
        return formattedString ?? "00:00"
    }

    // MARK: Lifecycle

    init(loginId: String, duration: Date, loginIdentity: String) {
        self.loginId = loginId
        self.duration = duration
        self.loginIdentity = loginIdentity
    }

    // MARK: Functions

    // set a timer for resend the code after one minutes
    func startTimer() {
        // Disable resend initially
        self.resendEnabled = false

        // Set the timeRemaining based on otpResendAt
        let currentDate = Date()
        self.timeRemaining = Int(self.duration.timeIntervalSince(currentDate))

        // Schedule the timer to tick every second
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }

            // Decrease the time remaining
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                // Invalidate the timer and enable the resend button
                self.timer?.invalidate()
                self.resendEnabled = true
            }
        }
    }

    func verifyOTP() async {
        guard self.isCodeComplete else {
            self.errorMessage = "Please enter the complete verification code."
            return
        }

        self.isLoading = true
        self.errorMessage = nil

        defer { isLoading = false }

        do {
            try await self.registrationService.verifyOTP(loginId: self.loginId, otp: self.otp, baseURL: DebugStore().baseURL)

            self.verificationSuccessful = true
            self.userLoggedIn = true
            Logger.userRegistration.info("OTP verified successfully.")

        } catch {
            self.errorMessage = "An error occurred during verification. Please check your OTP code and try again."
            self.isValid = false
            Logger.userRegistration.error("OTP verification failed: \(error.localizedDescription)")
        }
    }

    func resendOTP(loginId: String) async {
        do {
            let response = try await registrationService.resendOTP(loginId: loginId, baseURL: DebugStore().baseURL)
            self.duration = response.canRequestOtpResendAt
            self.otp = ""
            self.isValid = true
            self.errorMessage = nil
        } catch {
            Logger.userRegistration.info("error resending otp")
        }
    }

    private func resetValidity() {
        if !self.isValid, !self.isCodeComplete {
            self.isValid = false
            self.errorMessage = nil
        }
    }
}
