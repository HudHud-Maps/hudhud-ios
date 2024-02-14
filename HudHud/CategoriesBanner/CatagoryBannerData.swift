//
//  CatagoryBannerData.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct CatagoryBannerData:Identifiable {
	let id = UUID()
	let buttonColor: Color?
	let textColor: Color?
	let title: String?
	let icon: String?
	
	init(buttonColor: Color?,textColor: Color?, title: String?, icon: String?) {
		self.buttonColor = buttonColor
		self.textColor = textColor
		self.title = title
		self.icon = icon
	}
}
