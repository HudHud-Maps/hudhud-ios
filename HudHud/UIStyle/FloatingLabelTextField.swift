//
//  FloatingLabelTextField.swift
//  HudHud
//
//  Created by Alaa . on 27/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import iPhoneNumberField
import SwiftUI

// MARK: - FloatingLabelInputType

enum FloatingLabelInputType {
    case phone(phone: Binding<String>)
    case text(text: Binding<String>)
    case dropdown(choice: Binding<String>, options: [String])
    case datePicker(date: Binding<Date>, dateFormatter: DateFormatter)
}

// MARK: - FloatingLabelInputField

struct FloatingLabelInputField: View {

    // MARK: Properties

    var placeholder: String
    var inputType: FloatingLabelInputType

    @FocusState private var isFocused: Bool

    // MARK: Content

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading) {
                switch self.inputType {
                case let .phone(phone: phone):
                    iPhoneNumberField(text: phone)
                        .formatted()
                        .defaultRegion("SA")
                        .flagHidden(false)
                        .flagSelectable(true)
                        .prefixHidden(false)
                        .autofillPrefix(true)
                        .clearButtonMode(.whileEditing)
                        .hudhudFontStyle(.paragraphLarge)
                        .foregroundColor(Color.Colors.General._12Red)
                        .bold()
                        .padding(.bottom, 5)
                        .onChange(of: phone.wrappedValue) { _, newValue in
                            // Ensure the + sign is not removed
                            if !newValue.hasPrefix("+") {
                                phone.wrappedValue = "+" + newValue
                            }
                        }

                case let .text(binding):
                    TextField(self.placeholder, text: binding)
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
                        .hudhudFont()
                        .foregroundColor(Color.Colors.General._01Black)
                        .padding(.bottom, 5)
                        .focused(self.$isFocused)
                        .background(Color.clear)
                }
            }
            .background(Color.clear)

            // Bottom line
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.Colors.General._04GreyForLines)
                .padding(.top, 35)
        }
        .padding(.top, 8)
        .animation(.easeInOut, value: self.isFocused || !self.getTextField().isEmpty)
    }

    // MARK: Functions

    private func getTextField() -> String {
        switch self.inputType {
        case let .phone(phone: phone):
            return phone.wrappedValue
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
