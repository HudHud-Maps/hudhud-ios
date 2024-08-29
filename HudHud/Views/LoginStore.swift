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
    @Published var userInput: UserInput = .phone
    @Published var email: String = ""
    @Published var phone: String = ""

    var isInputEmpty: Bool {
        switch self.userInput {
        case .phone:
            return self.phone.isEmpty
        case .email:
            return self.email.isEmpty
        }
    }

    enum UserInput {
        case phone, email
    }

}
