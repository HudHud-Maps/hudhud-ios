//
//  DebugStore.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

class DebugStore: ObservableObject {
	@AppStorage("routingHost") var routingHost: String = "gh.maptoolkit.net"

	@Published var simulateRide: Bool = false

}
