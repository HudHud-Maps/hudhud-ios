//
//  FavoriteCategoriesData.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import POIService
import SFSafeSymbols
import SwiftUI

struct FavoriteCategoriesData: Identifiable {
    let id: Int
    let title: LocalizedStringResource
    let sfSymbol: SFSymbol
    let tintColor: Color?
    let item: ResolvedItem?
}
