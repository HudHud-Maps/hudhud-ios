//
//  LocationStatus.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

extension CLAuthorizationStatus {

    var allowed: Bool {
        return self == .authorizedAlways || self == .authorizedWhenInUse
    }

    var permissionStatus: UserLocationStore.PermissionStatus {
        if self.allowed {
            .enabled
        } else if self == .notDetermined {
            .notDetermined
        } else {
            .denied
        }
    }
}
