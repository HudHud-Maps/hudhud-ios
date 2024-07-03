//
//  NotificationManager.swift
//  HudHud
//
//  Created by Alaa . on 01/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    let center = UNUserNotificationCenter.current()

    // MARK: - Internal

    func requestAuthorization() async throws {
        do {
            try await self.center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Authorization failed: \(error)")
            throw error
        }
    }
}
