//
//  WebView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import OSLog
import SwiftUI
import WebKit

// MARK: - StreetViewWebView

struct StreetViewWebView: UIViewRepresentable {

	@StateObject private var scriptHandler = ScriptHandler()

	// MARK: - Properties

	@ObservedObject var viewModel: MotionViewModel

	let url: URL = .init(string: "https://iabderrahmane.github.io/")!

	// MARK: - Internal

	class Coordinator: ScriptHandlerDelegate {

		@Published var viewModel: MotionViewModel

		// MARK: - Lifecycle

		init(viewModel: MotionViewModel) {
			self.viewModel = viewModel
		}

		// MARK: - Fileprivate

		fileprivate func scriptHandler(_: ScriptHandler, didUpdate panorama: PanoramaInfo) {
			self.viewModel.position.heading = panorama.heading
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(viewModel: self.viewModel)
	}

	func makeUIView(context: Context) -> WKWebView {
		let config = WKWebViewConfiguration()
		config.userContentController.add(self.scriptHandler, name: "viewUpdated")

		let webView = WKWebView(frame: .zero, configuration: config)

		let request = URLRequest(url: url)
		webView.load(request)

		self.scriptHandler.delegate = context.coordinator

		return webView
	}

	func updateUIView(_: WKWebView, context _: Context) {}
}

// MARK: - ScriptHandlerDelegate

private protocol ScriptHandlerDelegate: AnyObject {
	func scriptHandler(_ scriptHandler: ScriptHandler, didUpdate panorama: PanoramaInfo)
}

// MARK: - ScriptHandler

private class ScriptHandler: NSObject, ObservableObject, WKScriptMessageHandler {

	weak var delegate: ScriptHandlerDelegate?

	// MARK: - Internal

	func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: message.body, options: [])

			let decoder = JSONDecoder()
			let panoramaInfo = try decoder.decode(PanoramaInfo.self, from: jsonData)

			self.delegate?.scriptHandler(self, didUpdate: panoramaInfo)
		} catch {
			Logger.streetView.error("Error decoding JSON: \(error)")
		}
	}
}

// MARK: - PanoramaInfo

private struct PanoramaInfo: Codable {
	let lat: CLLocationDegrees
	let long: CLLocationDegrees
	let pitch: Double
	let heading: CLLocationDirection
}
