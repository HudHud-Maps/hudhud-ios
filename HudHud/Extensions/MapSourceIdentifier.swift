//
//  MapSourceIdentifier.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum MapSourceIdentifier {
	case pedestrianPolyline
	case points
	case routePoints
	case streetViewSymbols

	var identifier: String {
		switch self {
		case .pedestrianPolyline:
			return "pedestrian-polyline"
		case .points:
			return "points"
		case .routePoints:
			return "routePoints"
		case .streetViewSymbols:
			return "street-view-symbols"
		}
	}
}
