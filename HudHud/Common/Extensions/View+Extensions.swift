//
//  View+Extensions.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - SizePreferenceKey

struct SizePreferenceKey: PreferenceKey {

    // MARK: Static Properties

    static var defaultValue: CGSize = .zero

    // MARK: Static Functions

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - ReadSizeModifier

struct ReadSizeModifier: ViewModifier {

    // MARK: Properties

    let onChange: (CGSize) -> Void

    // MARK: Content

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { proxy in
                Color.clear.preference(key: SizePreferenceKey.self, value: proxy.size)
            })
            .onPreferenceChange(SizePreferenceKey.self, perform: self.onChange)
    }
}

extension View {

    func readSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        modifier(ReadSizeModifier(onChange: onChange))
    }
}

// MARK: - SafeAreaInsetsKey

private struct SafeAreaInsetsKey: EnvironmentKey {

    static var defaultValue: EdgeInsets {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.swiftUiInsets ?? .zero
    }
}

extension EnvironmentValues {

    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {

    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

private extension EdgeInsets {

    static var zero: EdgeInsets {
        return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
}
