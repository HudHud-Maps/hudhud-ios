//
//  POISheetStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 07/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import SwiftUI

@Observable
class POISheetStore {

    // MARK: Properties

    let item: ResolvedItem
    var openingHours = false

    let hours: [String: String] = [
        "Monday": "9:00 AM - 10:00 PM",
        "Tuesday": "9:00 AM - 10:00 PM",
        "Wednesday": "9:00 AM - 10:00 PM",
        "Thursday": "9:00 AM - 10:00 PM",
        "Friday": "Closed",
        "Saturday": "10:00 AM - 8:00 PM"
    ]

    // MARK: Lifecycle

    init(item: ResolvedItem, openingHours: Bool = false) {
        self.item = item
        self.openingHours = openingHours
    }

}
