//
//  Backport.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Backport

public struct Backport<Content> {
	public let content: Content

	// MARK: - Lifecycle

	public init(_ content: Content) {
		self.content = content
	}
}

extension Backport where Content: View {
	@ViewBuilder func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
		if #available(iOS 17, *) {
			content.safeAreaPadding(edges, length)
		} else {
			self.content.padding(edges, 100)
		}
	}

	@ViewBuilder func scrollClipDisabled() -> some View {
		if #available(iOS 17, *) {
			content.scrollClipDisabled()
		} else {
			self.content
		}
	}

	@ViewBuilder func sheet(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content subContent: @escaping () -> some View) -> some View where Content: View {
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.content.overlay(alignment: .bottomLeading) {
				subContent()
					.frame(width: 400, height: 400)
					.background(.white)
					.padding(.leading)
			}
		} else {
			self.content.sheet(isPresented: isPresented, onDismiss: onDismiss, content: subContent)
		}
	}

	@ViewBuilder
	func customSheet(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content subContent: @escaping () -> some View) -> some View where Content: View {
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.content.overlay(alignment: .bottomLeading) {
				VStack(spacing: 0) {
					subContent()
						.frame(width: 400, height: 1000)
						.background(Color.white)
						.cornerRadius(16)
						.overlay(alignment: .top) {
							Rectangle()
								.frame(width: 40, height: 6)
								.foregroundColor(Color.secondary)
								.cornerRadius(3)
								.padding(5)
						}
				}
			}

		} else {
			self.content.sheet(isPresented: isPresented, onDismiss: onDismiss, content: subContent)
		}
	}
}
