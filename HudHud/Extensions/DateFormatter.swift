//
//  DateFormatter.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
import Foundation

extension String {
    var formattedHour: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        if let hourFormatted = formatter.date(from: self) {
            return hourFormatted
        } else {
            return Date()
        }
    }
}
