//
//  HudhudSegmentedPicker.swift
//  HudHud
//
//  Created by Alaa . on 08/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - HudhudSegmentedPicker

struct HudhudSegmentedPicker: View {

    // MARK: Properties

    @Binding var selected: String
    let options: [SegmentOption]

    // MARK: Content

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(self.options.enumerated()), id: \.offset) { index, option in
                HudhudSegmentedPickerButton(
                    option: option,
                    isSelected: self.selected == option.value,
                    action: { withAnimation { self.selected = option.value } }
                )

                // Only add the divider if it's not the last option
                if index < self.options.count - 1 {
                    Divider()
                        .frame(maxWidth: 1, maxHeight: 16)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 35)
        .background(Color.Colors.General._03LightGrey)
        .cornerRadius(8)
    }
}

#Preview {
    @State var selection = "1"
    @State var options = ["1", "2", "3"]
    return HudhudSegmentedPicker(selected: $selection, options: [SegmentOption(value: "1", label: .text("1")), SegmentOption(value: "2", label: .text("2")), SegmentOption(value: "3", label: .text("3"))])
}

// MARK: - SegmentOption

struct SegmentOption {

    // MARK: Nested Types

    enum SegmentLabel {
        case text(String)
        case symbol(SFSymbol)
        case textWithSymbol(String, SFSymbol)
        case image(Image)
        case images([Image])
    }

    // MARK: Properties

    let value: String
    let label: SegmentLabel
}

// MARK: - HudhudSegmentedPickerButton

struct HudhudSegmentedPickerButton: View {

    // MARK: Properties

    let option: SegmentOption
    var isSelected: Bool
    var action: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: self.action) {
            HStack {
                switch self.option.label {
                case let .text(text):
                    Text(text)
                        .hudhudFont(.subheadline)

                case let .symbol(symbol):
                    Image(systemSymbol: symbol)

                case let .textWithSymbol(text, symbol):
                    Image(systemSymbol: symbol)
                        .font(.caption)
                        .foregroundStyle(Color.Colors.General._13Orange)
                    Text(text)
                        .hudhudFont(.subheadline)

                case let .image(image):
                    image
                        .font(.callout)

                case let .images(images):
                    HStack {
                        ForEach(images.indices, id: \.self) { index in
                            images[index]
                                .font(.callout)
                        }
                    }
                }
            }
            .foregroundColor(self.isSelected ? .white : Color.Colors.General._02Grey)
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(self.isSelected ? Color.Colors.General._10GreenMain : Color.Colors.General._03LightGrey)
        }
    }
}
