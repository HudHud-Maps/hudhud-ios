//
//  CatagoryBannerData.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct CatagoryBannerData: Identifiable {
	let id = UUID()
	let buttonColor: Color?
	let textColor: Color?
	let title: String
	let iconSystemName: String

	// MARK: - Test Data

	static let cateoryBannerFakeData = [
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .green,
			title: "Restaurant",
			iconSystemName: "fork.knife"
		),
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .brown,
			title: "Shop",
			iconSystemName: "bag.circle.fill"
		),
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .orange,
			title: "Hotels",
			iconSystemName: "bed.double.fill"
		),
		CatagoryBannerData(
			buttonColor: Color(UIColor.systemBackground),
			textColor: .yellow,
			title: "Coffee Shop",
			iconSystemName: "cup.and.saucer.fill"
		)
	]

	// MARK: - Lifecycle

	init(buttonColor: Color?, textColor: Color?, title: String, iconSystemName: String) {
		self.buttonColor = buttonColor
		self.textColor = textColor
		self.title = title
		self.iconSystemName = iconSystemName
	}
}
