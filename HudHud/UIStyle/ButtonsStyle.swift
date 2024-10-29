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

    // MARK: Properties

    let backgroundColor: Color
    let foregroundColor: Color

    // MARK: Content

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

    // MARK: Properties

    @Binding var isLoading: Bool

    let backgroundColor: Color
    let foregroundColor: Color

    // MARK: Content

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .tint(.white)
                .frame(width: 20, height: 20)
                .opacity(self.isLoading ? 1 : 0)
            configuration.label
                .opacity(self.isLoading ? 0 : 1) // Hide text when loading
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .foregroundStyle(self.foregroundColor)
        .hudhudFont()
        .bold()
        .frame(maxWidth: .infinity)
        .background(self.backgroundColor.opacity(self.isLoading ? 0.7 : 1))
        .clipShape(.rect(cornerRadius: 30))
    }
}
