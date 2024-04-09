//
//  ViewBuilder.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

/// A workaround for `do/catch` statements not working with result builders.
/// From: https://forums.swift.org/t/what-is-the-correct-design-pattern-for-initializing-swiftui-view-state-from-a-function-that-can-throw-an-exception/63661/5
@ViewBuilder public func `do`(
	@ViewBuilder try success: () throws -> some View,
	@ViewBuilder catch failure: (any Error) -> some View
) -> some View {
	switch Result(catching: success) {
	case let .success(success): success
	case let .failure(error): failure(error)
	}
}
