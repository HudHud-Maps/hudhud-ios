//
//  NotificationBanner.swift
//  HudHud
//
//  Created by Patrick Kladek on 14.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

// MARK: - NotificationQueue

@MainActor
class NotificationQueue: ObservableObject {

    // MARK: Properties

    @Published var currentNotification: Notification?

    // MARK: Computed Properties

    private var queue: [Notification] = [] {
        didSet {
            if self.currentNotification != self.queue.first {
                self.currentNotification = self.queue.first
            }
        }
    }

    // MARK: Functions

    // MARK: - Internal

    func add(notification: Notification) {
        self.queue.append(notification)
    }

    func removeFirst() {
        self.queue.removeFirst()
    }
}

// MARK: - Notification

struct Notification: Identifiable, Equatable {

    // MARK: Properties

    var id: String
    let error: Error

    // MARK: Computed Properties

    var title: String {
        self.error.localizedDescription
    }

    var message: String? {
        guard let error = error as? LocalizedError else { return nil }

        return error.recoverySuggestion ?? error.failureReason
    }

    var hint: String? {
        guard let error = error as? LocalizedError else { return nil }

        return error.helpAnchor
    }

    // MARK: Lifecycle

    init(error: Error) {
        self.error = error
        self.id = String(describing: error)
    }

    // MARK: Static Functions

    // MARK: - Internal

    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - NotificationBanner

struct NotificationBanner: View {

    // MARK: Properties

    let notification: Notification

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.notification.title)
                        .bold()
                    if let message = self.notification.message {
                        Text(message)
                            .font(Font.system(size: 15, weight: Font.Weight.light, design: Font.Design.default))
                    }
                    if let hint = self.notification.hint {
                        Text(hint)
                            .font(Font.system(size: 12, weight: Font.Weight.light, design: Font.Design.default))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .foregroundColor(Color.white)
            .padding(12)
            .background(.red)
            .cornerRadius(8)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    NotificationBanner(notification: Notification(error: ToursprungError.invalidUrl(message: nil)))
        .padding()
}
