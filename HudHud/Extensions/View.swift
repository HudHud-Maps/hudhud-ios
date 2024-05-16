//
//  View.swift
//  HudHud
//
//  Created by Fatima Aljaber on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    var backport: Backport<Self> { Backport(self) }
}
