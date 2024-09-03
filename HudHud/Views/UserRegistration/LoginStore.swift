//
//  LoginStore.swift
//  HudHud
//
//  Created by Alaa . on 28/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - LoginStore

class LoginStore: ObservableObject {

    // MARK: Nested Types

    enum UserInput {
        case phone, email
    }

    enum Gender: String, CaseIterable {
        case female = "Female"
        case male = "Male"

    }

    // MARK: Properties

    @Published var userInput: UserInput = .phone
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var nick: String = "@"
    @Published var gender: String = ""
    @Published var birthday = Date()

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

}
