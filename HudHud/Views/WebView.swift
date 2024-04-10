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
		case missingCoordinate
		case invalidURL

		var errorDescription: String? {
			switch self {
			case .missingCoordinate:
				return "Coordinate missing"
			case .invalidURL:
				return "StreetView unavailable"
			}
		}

		var failureReason: String? {
			switch self {
			case .missingCoordinate:
				return "No Coordinate provided"
			case .invalidURL:
				return "Could not create URL for StreetView"
			}
		}

		var recoverySuggestion: String? {
			switch self {
			case .missingCoordinate,
				 .invalidURL:
				return "Contact Developer with a screenshot"
			}
		}
	}

	@StateObject private var scriptHandler = ScriptHandler()
	@State private var pageLoaded: Bool = false
	@State private var currentCoodinate: NonReactiveState<CLLocationCoordinate2D?> = NonReactiveState(wrappedValue: nil)

	// MARK: - Properties

	@ObservedObject var viewModel: MotionViewModel

	// MARK: - Lifecycle

	init(viewModel: MotionViewModel) throws {
		self.viewModel = viewModel
	}

	// MARK: - Internal

	class Coordinator: NSObject, ScriptHandlerDelegate, WKNavigationDelegate {

		@Published var viewModel: MotionViewModel
		@Binding var pageLoaded: Bool

		// MARK: - Lifecycle

		init(viewModel: MotionViewModel, pageLoaded: Binding<Bool>) {
			self.viewModel = viewModel
			self._pageLoaded = pageLoaded
		}

		// MARK: - Internal

		func webView(_: WKWebView, didFinish _: WKNavigation!) {
			Logger.streetView.notice("WebView finished loading")
			self.pageLoaded = true
		}

		// MARK: - Fileprivate

		fileprivate func scriptHandler(_: ScriptHandler, didUpdate panorama: PanoramaInfo) {
			if self.viewModel.position.heading != panorama.heading {
				Logger.streetView.notice("scriptHandler update panoramaInfo")
				self.viewModel.position.heading = panorama.heading
			}
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(viewModel: self.viewModel, pageLoaded: self.$pageLoaded)
	}

	func makeUIView(context: Context) -> WKWebView {
		self.scriptHandler.delegate = context.coordinator

		let config = WKWebViewConfiguration()
		config.userContentController.add(self.scriptHandler, name: "viewUpdated")
		let webView = WKWebView(frame: .zero, configuration: config)
		webView.navigationDelegate = context.coordinator
		webView.backgroundColor = .clear

		var components = URLComponents()
		components.scheme = "https"
		components.host = "iabderrahmane.github.io"
		components.path = "/"
		if let coordinate = self.viewModel.coordinate {
			components.queryItems = [
				URLQueryItem(name: "long", value: String(coordinate.longitude)),
				URLQueryItem(name: "lat", value: String(coordinate.latitude))
			]
		}
		if let url = components.url {
			let request = URLRequest(url: url)
			webView.load(request)
		}

		return webView
	}

	func updateUIView(_ webView: WKWebView, context _: Context) {
		guard self.pageLoaded else {
			return
		}
		defer {
			self.currentCoodinate.wrappedValue = self.viewModel.coordinate
		}
		guard let coordinate = self.viewModel.coordinate,
			  self.currentCoodinate.wrappedValue != self.viewModel.coordinate else {
			return
		}

		let javascript = "changeLocation({long: \(coordinate.longitude), lat: \(coordinate.latitude)});"
		Logger.streetView.notice("javascript call: \(javascript)")
		webView.evaluateJavaScript(javascript) { _, error in
			if let error {
				Logger.streetView.error("Error evaluating JavaScript code: \(error)")
			}
		}
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
