//
//  Navigation.swift
//  HudHud
//
//  Created by Patrick Kladek on 16.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - Navigation

struct Navigation: UIViewControllerRepresentable {
	typealias UIViewControllerType = NavigationViewController

	@Binding var camera: MapViewCamera

	let styleSource: MapStyleSource
	let userLayers: [StyleLayerDefinition]

	public var gestures = [MapGesture]()
	public var mapViewContentInset: UIEdgeInsets = .zero

	var onStyleLoaded: ((MLNStyle) -> Void)?
	var onViewPortChanged: ((MapViewPort) -> Void)?

	/// 'Escape hatch' to MLNMapView until we have more modifiers.
	/// See ``unsafeMapViewModifier(_:)``
	var unsafeMapViewModifier: ((NavigationMapView) -> Void)?
	var controls: [MapControl] = [
		CompassView(),
		LogoView(),
		AttributionButton()
	]

	private var locationManager: MLNLocationManager?

	// MARK: - Lifecycle

	public init(styleURL: URL,
				camera: Binding<MapViewCamera> = .constant(.default()),
				locationManager: MLNLocationManager? = nil,
				@MapViewContentBuilder _ makeMapContent: () -> [StyleLayerDefinition] = { [] }) {
		self.styleSource = .url(styleURL)
		_camera = camera
		self.userLayers = makeMapContent()
		self.locationManager = locationManager
	}

	// MARK: - Internal

	// MARK: - Navigation

	func makeUIViewController(context: Context) -> MapboxNavigation.NavigationViewController {
		let navigationController = NavigationViewController(for: nil)
		guard let mapView = navigationController.mapView else {
			fatalError("Could not create mapview")
		}

		mapView.delegate = context.coordinator

		// Apply modifiers, suppressing camera update propagation (this messes with setting our initial camera as
		// content insets can trigger a change)
//		context.coordinator.suppressCameraUpdatePropagation = true
//		self.applyModifiers(mapView, runUnsafe: false)
//		context.coordinator.suppressCameraUpdatePropagation = false

		mapView.locationManager = self.locationManager

		switch self.styleSource {
		case let .url(styleURL):
			mapView.styleURL = styleURL
		}

		context.coordinator.updateCamera(mapView: mapView,
										 camera: self.$camera.wrappedValue,
										 animated: false)
		mapView.locationManager = mapView.locationManager

		return navigationController
	}

	func updateUIViewController(_: MapboxNavigation.NavigationViewController, context _: Context) {}

	func makeCoordinator() -> NavigationCoordinator {
		return NavigationCoordinator(parent: self,
									 onGesture: { processGesture($0, $1) },
									 onViewPortChanged: { self.onViewPortChanged?($0) })
	}
}

extension Navigation {

	@MainActor func registerGesture(_ mapView: NavigationMapView, _ context: Context, gesture: MapGesture) {
		switch gesture.method {
		case let .tap(numberOfTaps: numberOfTaps):
			let gestureRecognizer = UITapGestureRecognizer(target: context.coordinator,
														   action: #selector(context.coordinator.captureGesture(_:)))
			gestureRecognizer.numberOfTapsRequired = numberOfTaps
			if numberOfTaps == 1 {
				// If a user double taps to zoom via the built in gesture, a normal
				// tap should not be triggered.
				if let doubleTapRecognizer = mapView.gestureRecognizers?
					.first(where: {
						$0 is UITapGestureRecognizer && ($0 as! UITapGestureRecognizer).numberOfTapsRequired == 2
					}) {
					gestureRecognizer.require(toFail: doubleTapRecognizer)
				}
			}
			mapView.addGestureRecognizer(gestureRecognizer)
			gesture.gestureRecognizer = gestureRecognizer

		case let .longPress(minimumDuration: minimumDuration):
			let gestureRecognizer = UILongPressGestureRecognizer(target: context.coordinator,
																 action: #selector(context.coordinator
																 	.captureGesture(_:)))
			gestureRecognizer.minimumPressDuration = minimumDuration

			mapView.addGestureRecognizer(gestureRecognizer)
			gesture.gestureRecognizer = gestureRecognizer
		}
	}

	@MainActor func processGesture(_ mapView: NavigationMapView, _ sender: UIGestureRecognizer) {
		guard let gesture = gestures.first(where: { $0.gestureRecognizer == sender }) else {
			assertionFailure("\(sender) is not a registered UIGestureRecongizer on the MapView")
			return
		}

		// Process the gesture into a context response.
		let context = self.processContextFromGesture(mapView, gesture: gesture, sender: sender)
		// Run the context through the gesture held on the MapView (emitting to the MapView modifier).
		switch gesture.onChange {
		case let .context(action):
			action(context)
		case let .feature(action, layers):
			let point = sender.location(in: sender.view)
			let features = mapView.visibleFeatures(at: point, styleLayerIdentifiers: layers)
			action(context, features)
		}
	}

	@MainActor func processContextFromGesture(_ mapView: NavigationMapView, gesture: MapGesture,
											  sender: UIGestureRecognizing) -> MapGestureContext {
		// Build the context of the gesture's event.
		let point: CGPoint = switch gesture.method {
		case let .tap(numberOfTaps: numberOfTaps):
			// Calculate the CGPoint of the last gesture tap
			sender.location(ofTouch: numberOfTaps - 1, in: mapView)
		case .longPress:
			// Calculate the CGPoint of the long process gesture.
			sender.location(in: mapView)
		}

		return MapGestureContext(gestureMethod: gesture.method,
								 state: sender.state,
								 point: point,
								 coordinate: mapView.convert(point, toCoordinateFrom: mapView))
	}
}

// MARK: - NavigationCoordinator

final class NavigationCoordinator: NSObject {

	weak var navigationController: NavigationViewController?
	var parent: Navigation

	// Storage of variables as they were previously; these are snapshot
	// every update cycle so we can avoid unnecessary updates
	private var snapshotUserLayers: [StyleLayerDefinition] = []
	private var snapshotCamera: MapViewCamera?
	private var snapshotStyleSource: MapStyleSource?

	// Indicates whether we are currently in a push-down camera update cycle.
	// This is necessary in order to ensure we don't keep trying to reset a state value which we were already processing
	// an update for.
	var suppressCameraUpdatePropagation = false

	var onStyleLoaded: ((MLNStyle) -> Void)?
	var onGesture: (NavigationMapView, UIGestureRecognizer) -> Void
	var onViewPortChanged: (MapViewPort) -> Void

	// MARK: - Lifecycle

	init(parent: Navigation,
		 onGesture: @escaping (NavigationMapView, UIGestureRecognizer) -> Void,
		 onViewPortChanged: @escaping (MapViewPort) -> Void) {
		self.parent = parent
		self.onGesture = onGesture
		self.onViewPortChanged = onViewPortChanged
	}

	// MARK: - Internal

	// MARK: - NavigationCoordinator

	@objc func captureGesture(_ sender: UIGestureRecognizer) {
		guard let mapView = self.navigationController?.mapView else {
			return
		}

		self.onGesture(mapView, sender)
	}

	@MainActor func updateCamera(mapView: MLNMapViewCameraUpdating, camera: MapViewCamera, animated: Bool) {
		guard camera != self.snapshotCamera else {
			// No action - camera has not changed.
			return
		}

		self.suppressCameraUpdatePropagation = true
		defer {
			suppressCameraUpdatePropagation = false
		}

		switch camera.state {
		case let .centered(onCoordinate: coordinate, zoom: zoom, pitch: pitch, direction: direction):
			mapView.userTrackingMode = .none
			mapView.setCenter(coordinate,
							  zoomLevel: zoom,
							  direction: direction,
							  animated: animated)
			mapView.minimumPitch = pitch.rangeValue.lowerBound
			mapView.maximumPitch = pitch.rangeValue.upperBound
		case let .trackingUserLocation(zoom: zoom, pitch: pitch, direction: direction):
			mapView.userTrackingMode = .follow
			// Needs to be non-animated or else it messes up following
			mapView.setZoomLevel(zoom, animated: false)
			mapView.direction = direction
			mapView.minimumPitch = pitch.rangeValue.lowerBound
			mapView.maximumPitch = pitch.rangeValue.upperBound
		case let .trackingUserLocationWithHeading(zoom: zoom, pitch: pitch):
			mapView.userTrackingMode = .followWithHeading
			// Needs to be non-animated or else it messes up following
			mapView.setZoomLevel(zoom, animated: false)
			mapView.minimumPitch = pitch.rangeValue.lowerBound
			mapView.maximumPitch = pitch.rangeValue.upperBound
		case let .trackingUserLocationWithCourse(zoom: zoom, pitch: pitch):
			mapView.userTrackingMode = .followWithCourse
			// Needs to be non-animated or else it messes up following
			mapView.setZoomLevel(zoom, animated: false)
			mapView.minimumPitch = pitch.rangeValue.lowerBound
			mapView.maximumPitch = pitch.rangeValue.upperBound
		case let .rect(boundingBox, padding):
			mapView.setVisibleCoordinateBounds(boundingBox,
											   edgePadding: padding,
											   animated: animated,
											   completionHandler: nil)
		case .showcase:
			// TODO: Need a method these/or to finalize a goal here.
			break
		}

		self.snapshotCamera = camera
	}
}

extension NavigationCoordinator: MLNMapViewDelegate {}

extension Navigation {
	/// Perform an action when the map view has loaded its style and all locally added style definitions.
	///
	/// - Parameter perform: The action to perform with the loaded style.
	/// - Returns: The modified map view.
	func onStyleLoaded(_ perform: @escaping (MLNStyle) -> Void) -> Navigation {
		var newMapView = self
		newMapView.onStyleLoaded = perform
		return newMapView
	}

	/// Allows you to set properties of the underlying MLNMapView directly
	/// in cases where these have not been ported to DSL yet.
	/// Use this function to modify various properties of the MLNMapView instance.
	/// For example, you can enable the display of the user's location on the map by setting `showUserLocation` to true.
	///
	/// This is an 'escape hatch' back to the non-DSL world
	/// of MapLibre for features that have not been ported to DSL yet.
	/// Be careful not to use this to modify properties that are
	/// already ported to the DSL, like the camera for example, as your
	/// modifications here may break updates that occur with modifiers.
	/// In particular, this modifier is potentially dangerous as it runs on
	/// EVERY call to `updateUIView`.
	///
	/// - Parameter modifier: A closure that provides you with an MLNMapView so you can set properties.
	/// - Returns: A MapView with the modifications applied.
	///
	/// Example:
	/// ```swift
	///  MapView()
	///     .mapViewModifier { mapView in
	///         mapView.showUserLocation = true
	///     }
	/// ```
	///
	func unsafeMapViewModifier(_ modifier: @escaping (MLNMapView) -> Void) -> Navigation {
		var newMapView = self
		newMapView.unsafeMapViewModifier = modifier
		return newMapView
	}

	// MARK: Default Gestures

	/// Add an tap gesture handler to the MapView
	///
	/// - Parameters:
	///   - count: The number of taps required to run the gesture.
	///   - onTapChanged: Emits the context whenever the gesture changes (e.g. began, ended, etc), that also contains
	/// information like the latitude and longitude of the tap.
	/// - Returns: The modified map view.
	func onTapMapGesture(count: Int = 1,
						 onTapChanged: @escaping (MapGestureContext) -> Void) -> Navigation {
		var newMapView = self

		// Build the gesture and link it to the map view.
		let gesture = MapGesture(method: .tap(numberOfTaps: count),
								 onChange: .context(onTapChanged))
		newMapView.gestures.append(gesture)

		return newMapView
	}

	/// Add an tap gesture handler to the MapView that returns any visible map features that were tapped.
	///
	/// - Parameters:
	///   - count: The number of taps required to run the gesture.
	///   - on layers: The set of layer ids that you would like to check for visible features that were tapped. If no
	/// set is provided, all map layers are checked.
	///   - onTapChanged: Emits the context whenever the gesture changes (e.g. began, ended, etc), that also contains
	/// information like the latitude and longitude of the tap. Also emits an array of map features that were tapped.
	/// Returns an empty array when nothing was tapped on the "on" layer ids that were provided.
	/// - Returns: The modified map view.
	func onTapMapGesture(count: Int = 1, on layers: Set<String>?,
						 onTapChanged: @escaping (MapGestureContext, [any MLNFeature]) -> Void) -> Navigation {
		var newMapView = self

		// Build the gesture and link it to the map view.
		let gesture = MapGesture(method: .tap(numberOfTaps: count),
								 onChange: .feature(onTapChanged, layers: layers))
		newMapView.gestures.append(gesture)

		return newMapView
	}

	/// Add a long press gesture handler to the MapView
	///
	/// - Parameters:
	///   - minimumDuration: The minimum duration in seconds the user must press the screen to run the gesture.
	///   - onPressChanged: Emits the context whenever the gesture changes (e.g. began, ended, etc).
	/// - Returns: The modified map view.
	func onLongPressMapGesture(minimumDuration: Double = 0.5,
							   onPressChanged: @escaping (MapGestureContext) -> Void) -> Navigation {
		var newMapView = self

		// Build the gesture and link it to the map view.
		let gesture = MapGesture(method: .longPress(minimumDuration: minimumDuration),
								 onChange: .context(onPressChanged))
		newMapView.gestures.append(gesture)

		return newMapView
	}

	func mapViewContentInset(_ inset: UIEdgeInsets) -> Self {
		var result = self

		result.mapViewContentInset = inset

		return result
	}

	func mapControls(@MapControlsBuilder _ buildControls: () -> [MapControl]) -> Self {
		var result = self

		result.controls = buildControls()

		return result
	}

	func onMapViewPortUpdate(_ onViewPortChanged: @escaping (MapViewPort) -> Void) -> Self {
		var result = self
		result.onViewPortChanged = onViewPortChanged
		return result
	}
}
