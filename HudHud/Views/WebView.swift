//
//  WebView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapLibreSwiftUI
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
	@Binding var camera: MapViewCamera

	// MARK: - Internal

	class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
		let viewModel: MotionViewModel
		@Binding var camera: MapViewCamera

		// MARK: - Lifecycle

		init(viewModel: MotionViewModel, camera: Binding<MapViewCamera>) {
			self.viewModel = viewModel
			self._camera = camera
		}

		// MARK: - Internal

		func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
			do {
				let panoramaInfo = try DictionaryDecoder().decode(PanoramaInfo.self, from: message.body)

				self.update(for: panoramaInfo)
			} catch {
				Logger.streetView.error("Error decoding JSON: \(error)")
			}
		}

		func webView(_ webView: WKWebView, didFinish _: WKNavigation) {
			Logger.streetView.notice("WebView finished loading")
			self.viewModel.pageLoaded = true
			Task {
				do {
					let info: PanoramaInfo = try await webView.getPanoramaInfo()
					Logger.streetView.notice("didFinish panorama info: \(String(describing: info))")

					await MainActor.run {
						self.update(for: info)
					}
				} catch {
					Logger.streetView.error("didFinish Error while evaluating js function: \(error)")
				}
			}
		}

		func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation) {
			Logger.streetView.notice("WebView started loading")
			self.viewModel.pageLoaded = false
		}

		func webView(_: WKWebView, didFail _: WKNavigation!, withError error: any Error) {
			// what should we do here?
			Logger.streetView.notice("WebView failed: \(error)")
		}

		// MARK: - Fileprivate

		fileprivate func update(for panoramaInfo: PanoramaInfo) {
			if self.viewModel.position.heading != panoramaInfo.heading || (self.viewModel.coordinate != nil && panoramaInfo.coordinate.distance(from: self.viewModel.coordinate!) > 1) { // swiftlint:disable:this force_unwrapping
				Logger.streetView.notice("Received JS Coordinate: \(panoramaInfo.coordinate.latitude), \(panoramaInfo.coordinate.longitude)")
				self.viewModel.position.heading = panoramaInfo.heading
				self.viewModel.coordinate = panoramaInfo.coordinate
				withAnimation {
					self.camera = .center(panoramaInfo.coordinate, zoom: 14)
				}
			}
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(viewModel: self.viewModel, camera: self.$camera)
	}

	func makeUIView(context: Context) -> WKWebView {
		Logger.streetView.notice("making new webview")

		let config = WKWebViewConfiguration()

		// Using .nonPersistent() works as exptected but is slow.
		// .default() caches but there seems to be a race condition and its undefined which image is shown :(
		config.websiteDataStore = .nonPersistent()
//		config.websiteDataStore = .default()
		config.userContentController.add(context.coordinator, name: "viewUpdated")
		let webView = WKWebView(frame: .zero, configuration: config)
		webView.navigationDelegate = context.coordinator
		webView.backgroundColor = .clear

		let coordinate = self.viewModel.coordinate!
		let queryItems = [
			URLQueryItem(name: "long", value: String(coordinate.longitude)),
			URLQueryItem(name: "lat", value: String(coordinate.latitude))
		]

		var components = URLComponents()
		components.scheme = "https"
		components.host = "iabderrahmane.github.io"
		components.queryItems = queryItems

//		let url = Bundle.main.url(forResource: "streetview", withExtension: "html")!.appending(queryItems: queryItems)
//		webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
//		Logger.streetView.notice("loading: \(url)")

		let url = components.url!
		let request = URLRequest(url: url)
		webView.load(request)
		Logger.streetView.notice("loading: \(url)")

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

		Task {
			do {
				let info: PanoramaInfo = try await webView.runJavaScriptFunction("getPanoramaInfo();")
				Logger.streetView.notice("UpdateUI location of webview: \(String(describing: info))")

				// If distance between target and actual location is too big, reload
				// This will reset heading to zero.
				// Might need to extend the WebView to take a heading parameter on launch
				guard info.coordinate.distance(from: coordinate) > 1 else { return }

				let jsWriteFunction = "changeLocation({long: \(coordinate.longitude), lat: \(coordinate.latitude)});"
				let result = try await webView.runJavaScript(jsWriteFunction)
				Logger.streetView.notice("UpdateUI JS Success: \(jsWriteFunction) returning: \(String(describing: result))")
			} catch {
				Logger.streetView.error("UpdateUI Error while evaluating js function: \(error)")
			}
		}
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

	func getPanoramaInfo() async throws -> PanoramaInfo {
		return try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.main.async {
				self.evaluateJavaScript("getPanoramaInfo();") { object, error in
					if let error {
						continuation.resume(throwing: error)
						return
					}

					if let object {
						do {
							let info = try DictionaryDecoder().decode(PanoramaInfo.self, from: object)
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
