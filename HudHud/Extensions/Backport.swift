//
//  Backport.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
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

    @ViewBuilder func symbolEffect(animate: Bool) -> some View {
        if #available(iOS 17, *) {
            content.symbolEffect(.bounce.down, value: animate)
        } else {
            self.content
        }
    }

    @ViewBuilder func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        if #available(iOS 17, *) {
            content.safeAreaPadding(edges, length)
        } else {
            self.content.padding(edges, 100)
        }
    }

    @ViewBuilder func buttonSafeArea(length: CGSize) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.safeAreaPadding(.leading, length.width)
        } else {
            self.safeAreaPadding(.bottom, length.height + 8)
        }
    }

    @ViewBuilder func scrollClipDisabled() -> some View {
        if #available(iOS 17, *) {
            content.scrollClipDisabled()
        } else {
            self.content
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

    @ViewBuilder func contentUnavailable(label: String? = nil, SFSymbol: SFSymbol? = nil, description: String? = nil) -> some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label("\(label ?? "Content Unavailable")", systemSymbol: SFSymbol ?? .docRichtextFill)
            } description: {
                Text("\(description ?? "No Content To be Shown Here.")")
            }
        } else {
            VStack {
                Image(systemSymbol: SFSymbol ?? .docRichtextFill)
                    .font(.title2)
                Text("\(label ?? "Content Unavailable")")
                    .hudhudFont(.title)
                Text("\(description ?? "No Content To be Shown Here.")")
                    .hudhudFont(.body)
            }
        }
    }
}

public extension Backport where Content == ButtonBorderShape {

    /// A shape that defers to the environment to determine the resolved button border shape.
    ///
    /// You can override the resolved shape in a given view hierarchy by using
    /// the ``View/buttonBorderShape(_:)`` modifier. If no button border shape
    /// is specified, it is resolved automatically for the given context and platform.
    static var buttonBorder: ButtonBorderShape = {
        if #available(iOS 17.0, *) {
            return .buttonBorder
        } else {
            // Fallback on earlier versions
            return .automatic
        }
    }()
}
