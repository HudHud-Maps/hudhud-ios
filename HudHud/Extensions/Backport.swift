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
	@ViewBuilder func safeArea(_ sheetSize: CGFloat) -> some View {
		if #available(iOS 17, *) {
			content.safeAreaPadding(.bottom, sheetSize)
		} else {
			self.content.padding(.bottom, 100)
		}
	}
}
