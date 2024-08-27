//
//  UserLoginView.swift
//  HudHud
//
//  Created by Alaa . on 27/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - UserLoginView

struct UserLoginView: View {
    @State var userInput: UserInput = .phone
    @State var email: String = ""
    @State var phone: String = ""
    @State var title: String = "Sign In"
    var body: some View {
        ZStack {
            Image(.loginBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                Spacer()
                Text(self.title)
                    .hudhudFont(.title)
                switch self.userInput {
                case .phone:
                    FloatingLabelTextField(text: self.$phone, placeholder: "Phone Number")
                        .padding(.top)
                case .email:
                    FloatingLabelTextField(text: self.$email, placeholder: "Email Address")
                        .padding(.top)
                }
                Spacer()
                Button {} label: {
                    Text(self.title)
                }
                .buttonStyle(LargeButtonStyle(backgroundColor: Color.Colors.General._07BlueMain.opacity(self.isInputEmpty ? 0.5 : 1), foregroundColor: .white))
                .disabled(self.isInputEmpty)
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    private var isInputEmpty: Bool {
        switch self.userInput {
        case .phone:
            return self.phone.isEmpty
        case .email:
            return self.email.isEmpty
        }
    }
}

#Preview {
    UserLoginView()
}

// MARK: - UserInput

enum UserInput {
    case phone, email
}
