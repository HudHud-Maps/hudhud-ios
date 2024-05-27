//
//  FloatingLabelTextField.swift
//  HudHud
//
//  Created by Alaa . on 27/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct FloatingLabelTextField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            Text(self.placeholder)
                .foregroundColor(.secondary)
                .offset(y: self.text.isEmpty ? 0 : -25)
                .scaleEffect(self.text.isEmpty ? 1 : 0.8, anchor: .leading)
                .animation(.default, value: self.text.isEmpty)

            TextField("", text: self.$text)
                .foregroundColor(.primary)
                .padding(.top, 20)
                .overlay(Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.secondary),
                    alignment: .bottom)
        }
        .padding(.top, 8)
        .animation(.default, value: self.text.isEmpty)
    }
}

#Preview {
    FloatingLabelTextField(text: .constant("home"), placeholder: "Name")
}
