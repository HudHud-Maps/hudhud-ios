//
//  FloatingLabelTextField.swift
//  HudHud
//
//  Created by Alaa . on 27/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - FloatingLabelInputType

enum FloatingLabelInputType {
    case text(text: Binding<String>)
    case dropdown(choice: Binding<String>, options: [String])
    case datePicker(date: Binding<Date>, dateFormatter: DateFormatter)
}

// MARK: - FloatingLabelInputField

struct FloatingLabelInputField: View {

    // MARK: Properties

    var placeholder: String
    var inputType: FloatingLabelInputType

    @State private var isFocused: Bool = false

    // MARK: Content

    var body: some View {
        ZStack(alignment: .leading) {
            Text(self.placeholder)
                .hudhudFont()
                .foregroundColor(.secondary)
                .offset(y: self.isFocused || !self.getTextField().isEmpty ? -35 : 0)
                .scaleEffect(self.isFocused || !self.getTextField().isEmpty ? 0.8 : 1, anchor: .leading)

            VStack(alignment: .leading) {
                switch self.inputType {
                case let .text(binding):
                    TextField("", text: binding, onEditingChanged: { editing in
                        self.isFocused = editing
                    })
                    .hudhudFont()
                    .foregroundColor(Color.Colors.General._01Black)
                    .bold()
                    .padding(.bottom, 5)

                case let .dropdown(binding, options):
                    Menu {
                        ForEach(options, id: \.self) { option in
                            Button(option) {
                                binding.wrappedValue = option
                            }
                        }
                    } label: {
                        HStack {
                            Text(binding.wrappedValue.isEmpty ? "" : binding.wrappedValue)
                                .hudhudFont()
                                .foregroundColor(binding.wrappedValue.isEmpty ? .secondary : Color.Colors.General._01Black)
                                .bold()
                                .padding(.bottom, 5)
                            Spacer()
                            Image(systemSymbol: .chevronDown)
                                .foregroundStyle(Color.Colors.General._02Grey)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.clear)

                case let .datePicker(binding, _):
                    DatePicker("", selection: binding, displayedComponents: .date)
                        .foregroundColor(.red)
                        .hudhudFont()
                        .foregroundColor(Color.Colors.General._01Black)
                        .padding(.bottom, 5)
                }
            }
            .background(Color.clear)

            // Bottom line
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.Colors.General._02Grey)
                .alignmentGuide(.bottom) { $0[.bottom] }
                .padding(.top, 35)
        }
        .padding(.top, 8)
        .animation(.easeInOut, value: self.isFocused || !self.getTextField().isEmpty)
    }

    // MARK: Functions

    // Helper to get the appropriate text based on the input type
    private func getTextField() -> String {
        switch self.inputType {
        case let .text(binding):
            return binding.wrappedValue
        case let .dropdown(binding, _):
            return binding.wrappedValue
        case let .datePicker(binding, dateFormatter):
            return dateFormatter.string(from: binding.wrappedValue)
        }
    }
}

#Preview {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium

    return VStack {
        FloatingLabelInputField(
            placeholder: "Email Address",
            inputType: .text(text: .constant("user@hudhud.sa"))
        )
        FloatingLabelInputField(
            placeholder: "Gender",
            inputType: .dropdown(choice: .constant(""), options: ["Male", "Female"])
        )
        FloatingLabelInputField(
            placeholder: "Date of Birth",
            inputType: .datePicker(date: .constant(Date()), dateFormatter: dateFormatter)
        )
    }
    .padding(.horizontal)
}
