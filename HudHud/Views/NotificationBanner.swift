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

class NotificationQueue: ObservableObject {

	var queue: [Notification] = [] {
		didSet {
			self.currentNotification = self.queue.first
		}
	}

	@Published var currentNotification: Notification? {
		didSet {
			print(#function)
		}
	}
}

// MARK: - Notification

struct Notification: Identifiable {
	var id: String
	let error: LocalizedError

	var title: String {
		self.error.localizedDescription
	}

	var message: String? {
		self.error.recoverySuggestion ?? self.error.failureReason
	}

	var hint: String? {
		self.error.helpAnchor
	}

	// MARK: - Lifecycle

	init(error: LocalizedError) {
		self.error = error
		self.id = String(describing: error)
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
					if let message = notification.message {
						Text(message)
							.font(Font.system(size: 15, weight: Font.Weight.light, design: Font.Design.default))
					}
					if let hint = notification.hint {
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
