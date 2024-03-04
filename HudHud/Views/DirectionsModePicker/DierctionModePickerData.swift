//
//  DierctionModePickerData.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SFSafeSymbols

struct DierctionModePickerData: Equatable {
	let mode: String 
	let sfSymbol: SFSymbol
	let duration: TimeInterval
	var selected: Bool
}

