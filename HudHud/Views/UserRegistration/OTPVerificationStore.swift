//
//  OTPVerificationStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 01/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation

@Observable
class OTPVerificationStore {

    // MARK: Properties

    var timer: Timer?
    let loginIdentity: String
    var code: [String] = Array(repeating: "", count: 6)
    var resendEnabled: Bool = false

    private var timeRemaining: Int = 60
    private let duration: Date

    // MARK: Computed Properties

    var isCodeComplete: Bool {
        return self.code.allSatisfy { $0.count == 1 }
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

    init(duration: Date, loginIdentity: String) {
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
}
