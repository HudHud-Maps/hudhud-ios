//
//  SearchSectionData.swift
//  HudHud
//
//  Created by Alaa . on 17/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct SearchSectionData<Destination: View, Subview: View> {
	let sectionTitle: String
	let destination: Destination?
	let subview: Subview
}
