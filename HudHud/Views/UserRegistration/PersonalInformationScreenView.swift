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

    @State var loginStore: LoginStore
    var onDismiss: () -> Void

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 30.0) {
            Text("Personal Information")
                .hudhudFont(.title)
                .foregroundStyle(Color.Colors.General._01Black)

            FloatingLabelInputField(placeholder: "First Name", inputType: .text(text: self.$loginStore.firstName))
            FloatingLabelInputField(placeholder: "Last Name", inputType: .text(text: self.$loginStore.lastName))
            FloatingLabelInputField(placeholder: "Nick", inputType: .text(text: self.$loginStore.nick))
            FloatingLabelInputField(placeholder: "Gender", inputType: .dropdown(choice: self.$loginStore.gender, options: LoginStore.Gender.allCases.map(\.rawValue)))
            FloatingLabelInputField(placeholder: "Birthday", inputType: .datePicker(date: self.$loginStore.birthday, dateFormatter: DateFormatter()))
            Spacer()
            Button {
                // here the session should change and open the app
                // should also sent the data to the backend
                self.onDismiss()
            } label: {
                Text("Create Account")
            }
            .buttonStyle(LargeButtonStyle(backgroundColor: Color.Colors.General._07BlueMain.opacity(self.loginStore.canCreateAccount ? 1 : 0.5), foregroundColor: .white))
            .disabled(!self.loginStore.canCreateAccount)
        }
        .padding()
    }
}

#Preview {
    @State var showLogin = true
    return PersonalInformationScreenView(loginStore: LoginStore(), onDismiss: {})
}
