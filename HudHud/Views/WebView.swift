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
				let panoramaInfo = try DictionaryDecoder().decode(PanoramaInfo.self, from: message.body)

				if self.viewModel.position.heading != panoramaInfo.heading {
					Logger.streetView.notice("scriptHandler update panoramaInfo")
					self.viewModel.position.heading = panoramaInfo.heading
					self.viewModel.coordinate = panoramaInfo.coordinate
				}
			} catch {
				Logger.streetView.error("Error decoding JSON: \(error)")
			}
		}

		func webView(_: WKWebView, didFinish _: WKNavigation) {
			Logger.streetView.notice("WebView finished loading")
			self.viewModel.pageLoaded = true
		}

		func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation) {
			Logger.streetView.notice("WebView started loading")
			self.viewModel.pageLoaded = false
		}

		func webView(_: WKWebView, didFail _: WKNavigation!, withError error: any Error) {
			// what should we do here?
			Logger.streetView.notice("WebView failed: \(error)")
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(viewModel: self.viewModel)
	}

	func makeUIView(context: Context) -> WKWebView {
		Logger.streetView.notice("making new webview")

		let config = WKWebViewConfiguration()
		config.websiteDataStore = .nonPersistent()
		config.userContentController.add(context.coordinator, name: "viewUpdated")
		let webView = WKWebView(frame: .zero, configuration: config)
		webView.navigationDelegate = context.coordinator
		webView.backgroundColor = .clear

		let coordinate = self.viewModel.coordinate!
//		let url = Bundle.main.url(forResource: "streetview", withExtension: "html")!.appending(queryItems: [
//			URLQueryItem(name: "long", value: String(coordinate.longitude)),
//			URLQueryItem(name: "lat", value: String(coordinate.latitude))
//		])
		var components = URLComponents()
		components.scheme = "https"
		components.host = "iabderrahmane.github.io"
		let url = components.url!

//		webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
//		Logger.streetView.notice("loading: \(url)")

		let request = URLRequest(url: url)
		webView.load(request)
		Logger.streetView.notice("loading: \(url)")

		return webView
	}

	func updateUIView(_: WKWebView, context _: Context) {
		guard self.viewModel.pageLoaded else {
			// this could lead to a situation where a user moves the pin while the screen is still loading
			return
		}

		guard let coordinate = self.viewModel.coordinate else {
			return
		}

//		Task {
//			do {
//				let info: PanoramaInfo = try await webView.runJavaScriptFunction("getPanoramaInfo();")
//				Logger.streetView.notice("info: \(String(describing: info))")
//				guard info.coordinate.distance(from: coordinate) < 1 else { return }
//
//				let jsWriteFunction = "changeLocation({long: \(coordinate.longitude), lat: \(coordinate.latitude)});"
		////				Logger.streetView.notice("javascript call: \(jsWriteFunction)")
//				let result = try await webView.runJavaScript(jsWriteFunction)
		////				Logger.streetView.notice("successfully called javascript: \(jsWriteFunction) returning: \(String(describing: result))")
//			} catch {
//				Logger.streetView.error("Error while evaluating js function: \(error)")
//			}
//		}
	}
}

extension WKWebView {

	func runJavaScriptFunction<T>(_ javaScriptString: String) async throws -> T where T: Decodable {
		return try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.main.async {
				self.evaluateJavaScript(javaScriptString) { object, error in
					if let error {
						continuation.resume(throwing: error)
						return
					}

					if let object {
						do {
							let info = try DictionaryDecoder().decode(T.self, from: object)
							continuation.resume(returning: info)
						} catch {
							continuation.resume(throwing: error)
						}
						return
					}

					assertionFailure("illegal javascript callback, object & error nil")
				}
			}
		}
	}

	@discardableResult
	func runJavaScript(_ javaScriptString: String) async throws -> Any? {
		return try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.main.async {
				self.evaluateJavaScript(javaScriptString) { object, error in
					if let error {
						continuation.resume(throwing: error)
						return
					}

					if let object {
						continuation.resume(returning: object)
						return
					}

					continuation.resume(returning: nil)
				}
			}
		}
	}
}

extension CLLocationCoordinate2D {

	func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
		let currentLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
		let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

		return currentLocation.distance(from: targetLocation)
	}
}

// MARK: - PanoramaInfo

struct PanoramaInfo: Codable {
	let coordinate: CLLocationCoordinate2D
	let pitch: Double
	let heading: CLLocationDirection

	var location: CLLocation {
		return CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
	}

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

// MARK: - DictionaryEncoder

class DictionaryEncoder {
	private let jsonEncoder = JSONEncoder()

	// MARK: - Internal

	/// Encodes given Encodable value into an array or dictionary
	func encode(_ value: some Encodable) throws -> Any {
		let jsonData = try self.jsonEncoder.encode(value)
		return try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
	}
}

// MARK: - DictionaryDecoder

class DictionaryDecoder {
	private let jsonDecoder = JSONDecoder()

	// MARK: - Internal

	/// Decodes given Decodable type from given array or dictionary
	func decode<T>(_ type: T.Type, from json: Any) throws -> T where T: Decodable {
		let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
		return try self.jsonDecoder.decode(type, from: jsonData)
	}
}
