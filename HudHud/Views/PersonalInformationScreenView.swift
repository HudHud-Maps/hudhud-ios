//
//  PersonalInformationScreenView.swift
//  HudHud
//
//  Created by Alaa . on 01/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct PersonalInformationScreenView: View {

    // MARK: Properties

    @StateObject private var loginStore = LoginStore()

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 30.0) {
            Text("Personal Information")
                .hudhudFont(.title)
                .foregroundStyle(Color.Colors.General._01Black)

            FloatingLabelInputField(placeholder: "Fisrt Name", inputType: .text(text: self.$loginStore.firstName))
            FloatingLabelInputField(placeholder: "Last Name", inputType: .text(text: self.$loginStore.lastName))
            FloatingLabelInputField(placeholder: "Nick", inputType: .text(text: self.$loginStore.nick))
            FloatingLabelInputField(placeholder: "Gender", inputType: .dropdown(choice: self.$loginStore.gender, options: self.loginStore.genders))
            FloatingLabelInputField(placeholder: "Birthday", inputType: .datePicker(date: self.$loginStore.birthday, dateFormatter: DateFormatter()))
            Spacer()
            Button {} label: {
                Text("Create Account")
            }
            .buttonStyle(LargeButtonStyle(backgroundColor: Color.Colors.General._07BlueMain.opacity(self.loginStore.canCreateAccount ? 1 : 0.5), foregroundColor: .white))
            .disabled(!self.loginStore.canCreateAccount)
        }
        .padding()
    }
}

#Preview {
    PersonalInformationScreenView()
}
