//
//  NotificationBanner.swift
//  HudHud
//
//  Created by Patrick Kladek on 14.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import ToursprungPOI

// MARK: - NotificationQueue

@MainActor
class NotificationQueue: ObservableObject {

	private var queue: [Notification] = [] {
		didSet {
			if self.currentNotification != self.queue.first {
				self.currentNotification = self.queue.first
			}
		}
	}

	@Published var currentNotification: Notification?

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
	var id: String
	let error: Error

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

	// MARK: - Lifecycle

	init(error: Error) {
		self.error = error
		self.id = String(describing: error)
	}

	// MARK: - Internal

	static func == (lhs: Notification, rhs: Notification) -> Bool {
		return lhs.id == rhs.id
	}
}

// MARK: - NotificationBanner

struct NotificationBanner: View {

	let notification: Notification

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

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	NotificationBanner(notification: .init(error: Toursprung.ToursprungError.invalidUrl))
		.padding()
}
