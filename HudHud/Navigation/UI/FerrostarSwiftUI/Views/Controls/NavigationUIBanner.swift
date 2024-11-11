//
//  NavigationUIBanner.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

public struct NavigationUIBanner<Label: View>: View {

    // MARK: Nested Types

    public enum Severity {
        case info
        case error
        case loading
    }

    // MARK: Properties

    var severity: Severity
    var backgroundColor: Color
    var label: Label

    // MARK: Lifecycle

    /// The basic Ferrostar SwiftUI button style.
    ///
    /// - Parameters:
    ///   - severity: The severity of the banner.
    ///   - backgroundColor: The capsule's background color.
    ///   - label: The label subview.
    public init(severity: NavigationUIBanner.Severity,
                backgroundColor: Color = Color(.systemBackground),
                @ViewBuilder label: () -> Label) {
        self.severity = severity
        self.backgroundColor = backgroundColor
        self.label = label()
    }

    // MARK: Content

    public var body: some View {
        HStack {
            self.image(for: self.severity)

            self.label
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(self.backgroundColor)
        .clipShape(Capsule())
    }

    @ViewBuilder
    func image(for severity: NavigationUIBanner.Severity) -> some View {
        switch severity {
        case .info:
            Image(systemSymbol: .infoCircleFill)
        case .error:
            Image(systemSymbol: .exclamationmarkTriangle)
        case .loading:
            Image(systemSymbol: .hourglassCircleFill)
        }
    }
}

#Preview {
    VStack {
        NavigationUIBanner(severity: .info) {
            Text(verbatim: "Something Useful")
        }

        NavigationUIBanner(severity: .loading) {
            Text(verbatim: "Rerouting...")
        }

        NavigationUIBanner(severity: .error) {
            Text(verbatim: "No Location Available")
        }
    }
    .padding()
    .background(Color.green)
}
