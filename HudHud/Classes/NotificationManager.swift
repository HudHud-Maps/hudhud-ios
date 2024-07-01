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
            try await self.center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            await self.checkAuthorizationStatus()
        } catch {
            print("Authorization failed: \(error)")
            throw error
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            print("Authorization not determined")
        case .denied:
            print("Authorization denied")
        case .authorized, .provisional:
            print("Authorization granted")
        case .ephemeral:
            print("Authorization granted ephemral")
        @unknown default:
            print("Unknown authorization status")
        }
    }
}
