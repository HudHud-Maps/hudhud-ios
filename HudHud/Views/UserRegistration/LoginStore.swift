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
        case OTPView
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

    var userInput: UserInput = .phone
    var email: String = ""
    var phone: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var nick: String = "@"
    var gender: String = ""
    var birthday = Date()
    var registrationService = RegistrationService()
    var registrationData: RegistrationResponse?

    var path = NavigationPath()

    // MARK: Computed Properties

    var isInputEmpty: Bool {
        switch self.userInput {
        case .phone:
            return self.phone.isEmpty
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

    var countryCode: String = "+966" {
        didSet {
            // Always ensure "+" is at the start
            if !self.countryCode.hasPrefix("+") {
                self.countryCode = "+" + self.countryCode.trimmingCharacters(in: .punctuationCharacters)
            }
        }
    }

    // MARK: Functions

    // Method to toggle between phone and email input types
    func toggleInputType() {
        self.userInput = (self.userInput == .email) ? .phone : .email
    }

    func login(inputText: String) async {
        do {
            let loginInput = self.userInput == .phone ? self.countryCode + inputText : inputText
            let registrationData = try await registrationService.login(loginInput: loginInput, baseURL: DebugStore().baseURL)
            self.registrationData = registrationData
            self.path.append(LoginStore.UserRegistrationPath.OTPView)
        } catch {
            self.registrationData = nil
            Logger.userRegistration.error("\(error.localizedDescription)")
        }
    }

}
