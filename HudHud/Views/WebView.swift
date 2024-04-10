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

	// MARK: - Properties

	@ObservedObject var viewModel: MotionViewModel

	// MARK: - Lifecycle

	init(viewModel: MotionViewModel) {
		self.viewModel = viewModel
	}

	// MARK: - Internal

	class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
		let viewModel: MotionViewModel

		// MARK: - Lifecycle

		init(viewModel: MotionViewModel) {
			self.viewModel = viewModel
		}

		// MARK: - Internal

		func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
			do {
				let jsonData = try JSONSerialization.data(withJSONObject: message.body, options: [])

				let decoder = JSONDecoder()
				let panoramaInfo = try decoder.decode(PanoramaInfo.self, from: jsonData)

				if self.viewModel.position.heading != panoramaInfo.heading {
					Logger.streetView.notice("scriptHandler update panoramaInfo")
					self.viewModel.position.heading = panoramaInfo.heading
					self.viewModel.coordinate = panoramaInfo.coordinate
				}
			} catch {
				Logger.streetView.error("Error decoding JSON: \(error)")
			}
		}

		func webView(_: WKWebView, didFinish _: WKNavigation!) {
			Logger.streetView.notice("WebView finished loading")
			self.viewModel.pageLoaded = true
		}

		func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
			Logger.streetView.notice("WebView started loading")
			self.viewModel.pageLoaded = false
		}

		func webView(_: WKWebView, didFail _: WKNavigation!, withError _: any Error) {
			// what should we do here?
		}

	}

	func makeCoordinator() -> Coordinator {
		Coordinator(viewModel: self.viewModel)
	}

	func makeUIView(context: Context) -> WKWebView {
		print("making new webview")

		let config = WKWebViewConfiguration()
		config.userContentController.add(context.coordinator, name: "viewUpdated")
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
		guard self.viewModel.pageLoaded else {
			// this could lead to a situation where a user moves the pin while the screen is still loading
			return
		}

		guard let coordinate = self.viewModel.coordinate else {
			return
		}

		let jsFunction = "getPanoramaInfo();"
		webView.evaluateJavaScript(jsFunction) { result, error in
			if let error {
				print("JavaScript execution error: \(error.localizedDescription)")
				return
			}

			guard let resultDict = result as? [String: Any] else {
				print("Unexpected result format")
				return
			}

			if let longitude = resultDict["long"] as? Double,
			   let latitude = resultDict["lat"] as? Double {
				let location1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
				let location2 = CLLocation(latitude: latitude, longitude: longitude)

				if location1.distance(from: location2) > 1 {
					// we should ask for a changeLocation that also accepts pitch and heading so we can keep this
					// in sync from app too
					let javascript = "changeLocation({long: \(coordinate.longitude), lat: \(coordinate.latitude)});"
					Logger.streetView.notice("javascript call: \(javascript)")

					webView.evaluateJavaScript(javascript) { _, error in
						if let error {
							Logger.streetView.error("Error evaluating JavaScript code: \(error)")
						}
					}
				}
			} else {
				print("Missing or invalid data types in result")
			}
		}
	}
}

// MARK: - PanoramaInfo

struct PanoramaInfo: Codable {
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
