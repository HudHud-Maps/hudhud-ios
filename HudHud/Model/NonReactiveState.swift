//
//  NonReactiveState.swift
//  HudHud
//
//  Created by Patrick Kladek on 10.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// from: https://tomaskafka.medium.com/improving-swiftui-performance-managing-view-state-without-unnecessary-redraws-1ea1399967fb
public class NonReactiveState<T> {
	private var value: T?

	public var wrappedValue: T? {
		get { return self.value }
		set { self.value = newValue }
	}

	// MARK: - Lifecycle

	public init(wrappedValue: T?) {
		self.value = wrappedValue
	}
}
