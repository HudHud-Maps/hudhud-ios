//
//  EnableableToggleStyle.swift
//  HudHud
//
//  Created by Patrick Kladek on 11.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - CustomToggle

struct EnableableToggleStyle: ToggleStyle {

    // MARK: Properties

    var enabledColor: Color = .primary
    var disabledColor: Color = .secondary

    @Environment(\.isEnabled) private var isEnabled

    // MARK: Content

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(self.isEnabled ? self.enabledColor : self.disabledColor)
            Spacer()
            Toggle(isOn: configuration.$isOn) {
                EmptyView()
            }
            .labelsHidden()
        }
    }
}
