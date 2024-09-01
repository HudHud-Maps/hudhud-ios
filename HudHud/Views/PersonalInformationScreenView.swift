//
//  PersonalInformationScreenView.swift
//  HudHud
//
//  Created by Alaa . on 01/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct PersonalInformationScreenView: View {
    @StateObject private var loginStore = LoginStore()
    @State var genders = ["Female", "Male"]
    var body: some View {
        VStack(alignment: .leading, spacing: 30.0) {
            Text("Personal Information")
                .hudhudFont(.title)
                .foregroundStyle(Color.Colors.General._01Black)

            FloatingLabelInputField(placeholder: "Fisrt Name", inputType: .text(text: self.$loginStore.firstName))
            FloatingLabelInputField(placeholder: "Last Name", inputType: .text(text: self.$loginStore.lastName))
            FloatingLabelInputField(placeholder: "Nick", inputType: .text(text: self.$loginStore.nick))
            FloatingLabelInputField(placeholder: "Gender", inputType: .dropdown(choice: self.$loginStore.gender, options: self.genders))
            FloatingLabelInputField(placeholder: "Birthday", inputType: .datePicker(date: self.$loginStore.birthday, dateFormatter: DateFormatter()))
            Spacer()
            Button {} label: {
                Text("Create Account")
            }
            .buttonStyle(LargeButtonStyle(backgroundColor: Color.Colors.General._07BlueMain.opacity(self.canCreateAccount ? 1 : 0.5), foregroundColor: .white))
            .disabled(!self.canCreateAccount)
        }
        .padding()
    }

    private var canCreateAccount: Bool {
        let allFieldsFilled = !self.loginStore.firstName.isEmpty &&
            !self.loginStore.lastName.isEmpty &&
            !self.loginStore.nick.isEmpty &&
            !self.loginStore.gender.isEmpty

        // Calculate the user's age
        let age = Calendar.current.dateComponents([.year], from: self.loginStore.birthday, to: Date()).year ?? 0

        // Ensure the age is greater than or equal to 6 years
        let isOldEnough = age >= 6

        return allFieldsFilled && isOldEnough
    }
}

#Preview {
    PersonalInformationScreenView()
}
