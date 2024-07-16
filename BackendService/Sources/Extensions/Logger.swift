//
//  Logger.swift
//  BackendService
//
//  Created by Patrick Kladek on 25.06.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle(for: RoutingService.self).bundleIdentifier! // swiftlint:disable:this force_unwrapping

    static let parser = Logger(subsystem: subsystem, category: "Parser")
}
