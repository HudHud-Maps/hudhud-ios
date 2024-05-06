//
//  ABCRouteConfigurationData.swift
//  HudHud
//
//  Created by Alaa . on 10/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapboxDirections
import MapKit
import POIService
import SFSafeSymbols
import SwiftUI

// MARK: - ABCRouteConfigurationItem

enum ABCRouteConfigurationItem: Hashable, Identifiable {

	case myLocation(Waypoint)
	case waypoint(ResolvedItem)

	var id: Self {
		return self
	}

	var name: String {
		switch self {
		case .myLocation:
			return "My Location"
		case let .waypoint(poi):
			return poi.title
		}
	}

	var icon: Image {
		switch self {
		case .myLocation:
			return Image(systemSymbol: .location)
		case .waypoint:
			return Image(systemSymbol: .mappin)
		}
	}
}

// MARK: - Line

struct Line: Shape {
	var from: CGPoint
	var to: CGPoint

	// MARK: - Internal

	func path(in _: CGRect) -> Path {
		Path { path in
			path.move(to: self.from)
			path.addLine(to: self.to)
		}
	}
}

// MARK: - ItemBoundsKey

struct ItemBoundsKey: PreferenceKey {
	static let defaultValue: [ABCRouteConfigurationItem.ID: Anchor<CGRect>] = [:]

	// MARK: - Internal

	static func reduce(value: inout [ABCRouteConfigurationItem.ID: Anchor<CGRect>], nextValue: () -> [ABCRouteConfigurationItem.ID: Anchor<CGRect>]) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}

}

extension CGRect {
	subscript(unitPoint: UnitPoint) -> CGPoint {
		CGPoint(x: minX + width * unitPoint.x, y: minY + height * unitPoint.y)
	}
}
