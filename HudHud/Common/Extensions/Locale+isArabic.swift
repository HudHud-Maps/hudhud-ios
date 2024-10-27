//
//  Locale+isArabic.swift
//  HudHud
//
//  Created by Naif Alrashed on 14/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

extension Locale {
    static var isArabic: Bool {
        guard let currentLanguage = preferredLanguages.first else {
            // if the device doesn't have a language (should never happen), default to arabic
            return true
        }
        return currentLanguage.lowercased().localizedStandardContains("ar")
    }
}

/// returns the most appropriate string for the current language. It shows the string from the other language
/// if the current language's string is nil or empty
func localized(english: String?, arabic: String?) -> String {
    if Locale.isArabic {
        if let arabic, !arabic.isEmpty {
            arabic
        } else {
            english ?? ""
        }
    } else if let english, !english.isEmpty {
        english
    } else {
        arabic ?? ""
    }
}
