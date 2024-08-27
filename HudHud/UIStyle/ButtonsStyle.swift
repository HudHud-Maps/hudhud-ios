//
//  ButtonsStyle.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - IconButton

struct IconButton: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .foregroundStyle(self.foregroundColor)
            .bold()
            .background(self.backgroundColor)
            .clipShape(Capsule())
            .background(.thickMaterial, in: Capsule())
    }
}

// MARK: - LargeButtonStyle

struct LargeButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .foregroundStyle(self.foregroundColor)
            .hudhudFont()
            .bold()
            .frame(maxWidth: .infinity)
            .background(self.backgroundColor)
            .clipShape(.rect(cornerRadius: 10))
    }
}
