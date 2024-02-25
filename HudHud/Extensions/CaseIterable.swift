//
//  CaseIterable.swift
//  HudHud
//
//  Created by Patrick Kladek on 19.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

extension CaseIterable where Self: Equatable {

	func next() -> Self {
		let all = Self.allCases
		let idx = all.firstIndex(of: self)! // swiftlint:disable:this force_unwrapping
		let next = all.index(after: idx)
		return all[next == all.endIndex ? all.startIndex : next]
	}
}
