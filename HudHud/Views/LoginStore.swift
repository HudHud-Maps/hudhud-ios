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

    // MARK: Properties

    @Published var userInput: UserInput = .phone
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var nick: String = "@"
    @Published var gender: String = ""
    @Published var birthday: Date = .init()

    // MARK: Computed Properties

    var isInputEmpty: Bool {
        switch self.userInput {
        case .phone:
            return self.phone.isEmpty
        case .email:
            return self.email.isEmpty
        }
    }

}
