//
//  Collection+Sugar.swift
//  BackendService
//
//  Created by Patrick Kladek on 25.06.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

public extension Collection {

    var hasElements: Bool {
        return self.isEmpty == false
    }
}
