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

	enum StreetViewError: LocalizedError {
		case invalidURL

		var errorDescription: String? {
			switch self {
			case .invalidURL:
				return "StreetView unavailable"
			}
		}

		var failureReason: String? {
			switch self {
			case .invalidURL:
				return "Could not create URL for StreetView"
			}
		}

		var recoverySuggestion: String? {
			switch self {
			case .invalidURL:
				return "Contact Developer with a screenshot"
			}
		}
	}

	@StateObject private var scriptHandler = ScriptHandler()

	// MARK: - Properties

	@ObservedObject var viewModel: MotionViewModel

	let url: URL

	// MARK: - Lifecycle

	init(viewModel: MotionViewModel) throws {
		self.viewModel = viewModel

		var components = URLComponents()
		components.scheme = "https"
		components.host = "iabderrahmane.github.io"
		components.path = "/"
		components.queryItems = [
			URLQueryItem(name: "long", value: String(viewModel.coordinate.longitude)),
			URLQueryItem(name: "lat", value: String(viewModel.coordinate.latitude))
		]
		guard let url = components.url else {
			throw StreetViewError.invalidURL
		}

		self.url = url
	}

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
		self.scriptHandler.delegate = context.coordinator

		let config = WKWebViewConfiguration()
		config.userContentController.add(self.scriptHandler, name: "viewUpdated")
		return WKWebView(frame: .zero, configuration: config)
	}

	func updateUIView(_ webView: WKWebView, context _: Context) {
		guard webView.url != self.url else {
			return
		}

		let request = URLRequest(url: self.url)
		webView.load(request)
	}
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

	// MARK: - Private

	private func handleViewUpdated(_: WKScriptMessage) {}
}

// MARK: - PanoramaInfo

private struct PanoramaInfo: Codable {
	let coordinate: CLLocationCoordinate2D
	let pitch: Double
	let heading: CLLocationDirection

	enum CodingKeys: String, CodingKey {
		case lat
		case long
		case pitch
		case heading
	}

	// MARK: - Lifecycle

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let lat = try container.decode(CLLocationDegrees.self, forKey: .lat)
		let long = try container.decode(CLLocationDegrees.self, forKey: .long)
		self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
		self.pitch = try container.decode(Double.self, forKey: .pitch)
		self.heading = try container.decode(CLLocationDirection.self, forKey: .heading)
	}

	// MARK: - Internal

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.coordinate.latitude, forKey: .lat)
		try container.encode(self.coordinate.longitude, forKey: .long)
		try container.encode(self.pitch, forKey: .pitch)
		try container.encode(self.heading, forKey: .heading)
	}
}
