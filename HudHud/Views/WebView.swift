//
//  WebView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import SwiftUI
import WebKit

// MARK: - WebView

struct WebView: UIViewRepresentable {
	@StateObject private var scriptHandler: ScriptHandler = .init()

	let url: URL

	// MARK: - Internal

	func makeUIView(context _: Context) -> WKWebView {
		let config = WKWebViewConfiguration()
		config.userContentController.add(self.scriptHandler, name: "viewUpdated")

		let webView = WKWebView(frame: .zero, configuration: config)

		let request = URLRequest(url: url)
		webView.load(request)

		return webView
	}

	func updateUIView(_ webView: WKWebView, context _: Context) {
		let request = URLRequest(url: url)
		webView.load(request)
	}
}

// MARK: - ScriptHandler

class ScriptHandler: NSObject, ObservableObject, WKScriptMessageHandler {

	struct PanoramaInfo: Codable {
		let lat: CLLocationDegrees
		let long: CLLocationDegrees
		let pitch: Double
		let heading: CLLocationDirection
	}

	func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
		print(#function)

		do {
			// Ensure the message body can be serialized
			let jsonData = try JSONSerialization.data(withJSONObject: message.body, options: [])

			// Decode the JSON data into your struct
			let decoder = JSONDecoder()
			let panoramaInfo = try decoder.decode(PanoramaInfo.self, from: jsonData)

			// Now you can use the PanoramaInfo instance
			print(panoramaInfo)
		} catch {
			print("Error decoding JSON: \(error)")
		}
	}
}
