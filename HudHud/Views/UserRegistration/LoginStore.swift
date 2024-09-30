//
//  LoginStore.swift
//  HudHud
//
//  Created by Alaa . on 28/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import OSLog
import SwiftUI

// MARK: - LoginStore

@Observable
class LoginStore {

    // MARK: Nested Types

    enum UserRegistrationPath: Hashable {
        case OTPView(loginIdentity: String, duration: Date)
        case personalInfoView
    }

    enum UserInput {
        case phone, email
    }

    enum Gender: String, CaseIterable {
        case female = "Female"
        case male = "Male"

    }

    // MARK: Properties

    var errorMessage: String = ""
    var userInput: UserInput = .phone
    var email: String = ""
    var phone: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var nick: String = "@"
    var gender: String = ""
    var birthday = Date()
    var path = NavigationPath()

    private var registrationService = RegistrationService()

    // MARK: Computed Properties

    var isInputEmpty: Bool {
        switch self.userInput {
        case .phone:
            return self.phone.isEmpty || self.phone == "+"
        case .email:
            return self.email.isEmpty
        }
    }

    var canCreateAccount: Bool {
        let allFieldsFilled = !self.firstName.isEmpty &&
            !self.lastName.isEmpty &&
            !self.nick.isEmpty &&
            !self.gender.isEmpty

        // Calculate the user's age
        let age = Calendar.current.dateComponents([.year], from: self.birthday, to: Date()).year ?? 0

        // Ensure the age is greater than or equal to 6 years
        let isOldEnough = age >= 6

        return allFieldsFilled && isOldEnough
    }

    // MARK: Functions

    // Method to toggle between phone and email input types
    func toggleInputType() {
        self.userInput = (self.userInput == .email) ? .phone : .email
    }

    func login(inputText: String) async {
        do {
            // remove white space before sending to backend
            let loginInput = inputText.replacingOccurrences(of: " ", with: "")
            let registrationData = try await registrationService.login(loginInput: loginInput, baseURL: DebugStore().baseURL)
            self.path.append(LoginStore.UserRegistrationPath.OTPView(loginIdentity: registrationData.loginIdentity, duration: registrationData.canRequestOtpResendAt))
        } catch {
            self.errorMessage = error.localizedDescription.description
        }
    }

}
