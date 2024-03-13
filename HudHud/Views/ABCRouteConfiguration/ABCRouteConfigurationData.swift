//
//  ABCRouteConfigurationData.swift
//  HudHud
//
//  Created by Alaa . on 10/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SFSafeSymbols
import SwiftUI
import POIService

enum ABCRouteConfigurationItem: Hashable, Identifiable {
	
case myLocation
case poi(POI)

var id: Self {

	   return self
   }

var name: String {
	switch self {
	case .myLocation:
		return "My Location"
	case .poi(let poi):
		return poi.title
	}
}

var icon: Image {
	switch self {
	case .myLocation:
		return Image(systemSymbol: .location)
	case .poi:
		return Image(systemSymbol: .mappin)
	}
}
}

struct Line: Shape {
	var from: CGPoint
	var to: CGPoint

	func path(in rect: CGRect) -> Path {
		Path { p in
			p.move(to: from)
			p.addLine(to: to)
		}
	}
}

struct ItemBoundsKey: PreferenceKey {
	static let defaultValue: [ABCRouteConfigurationItem.ID: Anchor<CGRect>] = [:]
	static func reduce(value: inout [ABCRouteConfigurationItem.ID : Anchor<CGRect>], nextValue: () -> [ABCRouteConfigurationItem.ID : Anchor<CGRect>]) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
	
}

extension CGRect {
	subscript(unitPoint: UnitPoint) -> CGPoint {
		CGPoint(x: minX + width * unitPoint.x, y: minY + height * unitPoint.y)
	}
}
