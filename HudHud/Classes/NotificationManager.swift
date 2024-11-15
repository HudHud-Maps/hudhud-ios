//
//  NotificationManager.swift
//  HudHud
//
//  Created by Alaa . on 01/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import OSLog
import UserNotifications

class NotificationManager: ObservableObject {

    // MARK: Properties

    let center = UNUserNotificationCenter.current()

    // MARK: Functions

    // MARK: - Internal

    func requestAuthorization() async throws {
        do {
            try await self.center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            Logger.notificationAuth.error("Authorization failed: \(error)")
            throw error
        }
    }
}
