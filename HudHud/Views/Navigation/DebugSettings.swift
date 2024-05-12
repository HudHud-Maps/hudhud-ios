//
//  DebugSettings.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

class DebugSettings: ObservableObject {
	@Published var routingURL: String = "gh.maptoolkit.net"
	@Published var isURLValid: Bool = true

	@Published var simulateRide: Bool = false

	// MARK: - Internal

	func validateCurrentURL() {
		self.testURLReachability(urlString: self.routingURL) { isValid in
			self.isURLValid = isValid
		}
	}

	// MARK: - Private

	private func testURLReachability(urlString: String, completion: @escaping (Bool) -> Void) {
		guard let url = URL(string: urlString) else {
			completion(false)
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "HEAD"

		URLSession.shared.dataTask(with: request) { _, response, error in
			let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
			DispatchQueue.main.async {
				completion(error == nil && statusCode == 200)
			}
		}.resume()
	}

}
