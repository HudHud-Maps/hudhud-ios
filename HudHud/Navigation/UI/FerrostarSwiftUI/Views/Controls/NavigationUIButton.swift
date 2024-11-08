//
//  NavigationUIButton.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - NavigationUIButtonStyle

public struct NavigationUIButtonStyle: ButtonStyle {

    // MARK: Lifecycle

    /// The ferrostar button style.
    public init() {}

    // MARK: Content

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color(.systemBackground))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
            .frame(minWidth: 52, minHeight: 52)
    }
}

// MARK: - NavigationUIButton

public struct NavigationUIButton<Label: View>: View {

    // MARK: Properties

    let action: () -> Void
    let label: Label

    // MARK: Lifecycle

    /// The basic Ferrostar SwiftUI button style.
    ///
    /// - Parameters:
    ///   - action: The action the button performs on tap.
    ///   - label: The label subview.
    public init(action: @escaping () -> Void, label: () -> Label) {
        self.action = action
        self.label = label()
    }

    // MARK: Content

    public var body: some View {
        Button {
            self.action()
        } label: {
            self.label
        }
        .buttonStyle(NavigationUIButtonStyle())
    }
}

#Preview {
    VStack {
        NavigationUIButton {} label: {
            Image(systemSymbol: .location)
        }

        NavigationUIButton {} label: {
            Text("Start Navigation")
        }
    }
    .padding()
    .background(Color.green)
}
