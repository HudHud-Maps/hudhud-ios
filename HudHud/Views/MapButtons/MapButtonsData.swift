//
//  MapButtonsData.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct MapButtonData: Identifiable, Equatable {
	let id = UUID()
	let sfSymbol: SFSymbol
	let action: () -> Void
	
	
		static func == (lhs: MapButtonData, rhs: MapButtonData) -> Bool {
			return lhs.id == rhs.id
			&& lhs.sfSymbol == rhs.sfSymbol
		}
}
