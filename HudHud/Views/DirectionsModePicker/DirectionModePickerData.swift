//
//  DierctionModePickerData.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SFSafeSymbols

struct DirectionModePickerData: Identifiable, Equatable {
	let mode: DirectionMode
	let duration: TimeInterval
	
	var id: DirectionMode { mode }
}

enum DirectionMode: Identifiable {
	
	case car, walk, bus, metro, bicycle
	
	var id: Self {
		   return self
	   }
	
	var iconName: SFSymbol {
		switch self {
		case .car: return .car
		case .walk: return .figureWalk
		case .bus: return .bus
		case .metro: return .trainSideFrontCar
		case .bicycle: return .bicycle
		}
	}
	var title: String {
		switch self {
		case .car: return "car"
		case .walk: return "walk"
		case .bus: return "bus"
		case .metro: return "metro"
		case .bicycle: return "bicycle"
		}
	}
}

