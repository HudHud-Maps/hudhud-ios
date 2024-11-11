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

struct HudhudSegmentedPicker<ValueType: Hashable>: View {

    // MARK: Properties

    @Binding var selected: ValueType
    let options: [SegmentOption<ValueType>]
    @ScaledMetric var frameHeight = 35

    // MARK: Content

    var body: some View {
        HStack(spacing: 0) {
            ForEach(self.options, id: \.value) { option in
                HudhudSegmentedPickerButton(option: option, isSelected: self.selected == option.value, action: {
                    withAnimation { self.selected = option.value }
                })
                if self.options.last?.value != option.value {
                    Divider()
                        .frame(maxWidth: 1, maxHeight: self.frameHeight / 2.0)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: self.frameHeight)
        .background(Color.Colors.General._03LightGrey)
        .cornerRadius(8)
    }
}

// MARK: - SegmentOption

struct SegmentOption<ValueType: Hashable> {

    // MARK: Nested Types

    enum SegmentLabel {
        case text(String)
        case symbol(SFSymbol)
        case textWithSymbol(String, SFSymbol)
        case image(Image)
        case images([Image])
    }

    // MARK: Properties

    let value: ValueType
    let label: SegmentLabel
}

// MARK: - HudhudSegmentedPickerButton

struct HudhudSegmentedPickerButton<ValueType: Hashable>: View {

    // MARK: Properties

    let option: SegmentOption<ValueType>
    let isSelected: Bool
    let action: () -> Void

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
            .padding()
            .frame(maxWidth: .infinity)
            .background(self.isSelected ? Color.Colors.General._10GreenMain : Color.Colors.General._03LightGrey)
        }
    }
}

#Preview {
    @Previewable @State var selection = "1"
    @Previewable @State var options = ["1", "2", "3"]
    return HudhudSegmentedPicker(selected: $selection, options: [
        SegmentOption(value: "1", label: .text("1")),
        SegmentOption(value: "2", label: .text("2")),
        SegmentOption(value: "3", label: .text("3"))
    ])
}
