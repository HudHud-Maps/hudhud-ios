//
//  FloatingLabelTextField.swift
//  HudHud
//
//  Created by Alaa . on 27/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct FloatingLabelTextField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            Text(self.placeholder)
                .hudhudFont()
                .foregroundColor(.secondary)
                .offset(y: self.text.isEmpty ? 0 : -25)
                .scaleEffect(self.text.isEmpty ? 1 : 0.8, anchor: .leading)

            TextField("", text: self.$text)
                .hudhudFont()
                .foregroundColor(Color.Colors.General._01Black)
                .padding(.top, 20)
                .overlay(Rectangle()
                    .frame(height: 2)
                    .foregroundColor(Color.Colors.General._04GreyForLines),
                    alignment: .bottom)
        }
        .padding(.top, 8)
        .animation(.default, value: self.text.isEmpty)
    }
}

#Preview {
    FloatingLabelTextField(text: .constant("User@hudhud.sa"), placeholder: "Email Address")
        .padding(.horizontal)
}
