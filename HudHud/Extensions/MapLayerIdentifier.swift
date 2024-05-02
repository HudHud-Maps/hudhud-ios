//
//  MapLayerIdentifier.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum MapLayerIdentifier {
	case routeLineCasing
	case routeLineInner
	case simpleCirclesRoute
	case simpleSymbolsRoute
	case simpleCirclesClustered
	case simpleSymbolsClustered
	case simpleCircles
	case simpleSymbols
	case streetViewSymbols

	var identifier: String {
		switch self {
		case .routeLineCasing:
			return "route-line-casing"
		case .routeLineInner:
			return "route-line-inner"
		case .simpleCirclesRoute:
			return "simple-circles-route"
		case .simpleSymbolsRoute:
			return "simple-symbols-route"
		case .simpleCirclesClustered:
			return "simple-circles-clustered"
		case .simpleSymbolsClustered:
			return "simple-symbols-clustered"
		case .simpleCircles:
			return "simple-circles"
		case .simpleSymbols:
			return "simple-symbols"
		case .streetViewSymbols:
			return "street-view-symbols"
		}
	}
}
