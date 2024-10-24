//
//  Backport.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapLibreSwiftUI
import SFSafeSymbols
import SwiftUI

// MARK: - Backport

public struct Backport<Content> {

    // MARK: Properties

    public let content: Content

    // MARK: Lifecycle

    public init(_ content: Content) {
        self.content = content
    }
}

extension Backport where Content: View {

    @ViewBuilder func streetViewSafeArea(length: CGFloat) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.content.safeAreaPadding(.trailing, length)
        } else {
            self.content.safeAreaPadding(.top, length + 8)
        }
    }

    @ViewBuilder func buttonSafeArea(length: CGSize) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.content.safeAreaPadding(.leading, length.width)
        } else {
            self.content.safeAreaPadding(.bottom, length.height + 8)
        }
    }

    @ViewBuilder
    func sheet(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad, isPresented.wrappedValue {
            self.content.overlay(alignment: .topLeading) {
                PadSheetGesture {
                    PadSheetView {
                        content()
                    }
                    .padding(.top)
                }
                .shadow(radius: 0.5)
                .padding(.horizontal)
            }
        } else {
            self.content.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        }
    }

    @ViewBuilder
    func sheet<Item>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View where Item: Identifiable {
        if UIDevice.current.userInterfaceIdiom == .pad, let wrappedValue = item.wrappedValue {
            self.content.overlay(alignment: .bottomLeading) {
                PadSheetGesture {
                    PadSheetView {
                        content(wrappedValue)
                    }
                }
                .shadow(radius: 0.5)
                .padding(.horizontal, 9.5)
            }
        } else {
            self.content.sheet(item: item, onDismiss: onDismiss, content: content)
        }
    }
}
