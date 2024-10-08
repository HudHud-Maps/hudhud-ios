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

struct POISheetStore {

    // MARK: Nested Types

    enum OpeningHours: String, CaseIterable {
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"
        case sunday = "Sunday"

        // MARK: Computed Properties

        var hours: String {
            switch self {
            case .monday, .tuesday, .wednesday, .thursday:
                return "9:00 AM - 10:00 PM"
            case .friday:
                return "Closed"
            case .saturday:
                return "10:00 AM - 8:00 PM"
            case .sunday:
                return "11:00 AM - 6:00 PM"
            }
        }
    }

    // MARK: Properties

    let item: ResolvedItem
    @Binding var openingHoursExpanded: Bool

}
