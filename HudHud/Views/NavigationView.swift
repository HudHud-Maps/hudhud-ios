//
//  NavigationView.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

typealias JSONDictionary = [String: Any]

// MARK: - NavigationView

public struct NavigationView: UIViewRepresentable {

	@Binding var camera: MapViewCamera

	let styleSource: MapStyleSource
	let userLayers: [StyleLayerDefinition]

	public var gestures = [MapGesture]()

	var onStyleLoaded: ((MLNStyle) -> Void)?
	var onViewPortChanged: ((MapViewPort) -> Void)?

	public var mapViewContentInset: UIEdgeInsets = .zero

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

	public init(
		styleURL: URL,
		camera: Binding<MapViewCamera> = .constant(.default()),
		locationManager: MLNLocationManager? = nil,
		@MapViewContentBuilder _ makeMapContent: () -> [StyleLayerDefinition] = { [] }
	) {
		self.styleSource = .url(styleURL)
		_camera = camera
		self.userLayers = makeMapContent()
		self.locationManager = locationManager
	}

	// MARK: - Public

	public func makeCoordinator() -> MapViewCoordinator {
		MapViewCoordinator(
			parent: self,
			onGesture: { processGesture($0, $1) },
			onViewPortChanged: { self.onViewPortChanged?($0) }
		)
	}

	public func makeUIView(context: Context) -> NavigationMapView {
		// Create the map view
		let mapView = NavigationMapView(frame: .zero)
		mapView.delegate = context.coordinator
		context.coordinator.mapView = mapView

		// Apply modifiers, suppressing camera update propagation (this messes with setting our initial camera as
		// content insets can trigger a change)
		context.coordinator.suppressCameraUpdatePropagation = true
		self.applyModifiers(mapView, runUnsafe: false)
		context.coordinator.suppressCameraUpdatePropagation = false

		mapView.locationManager = self.locationManager

		switch self.styleSource {
		case let .url(styleURL):
			mapView.styleURL = styleURL
		}

		context.coordinator.updateCamera(mapView: mapView,
										 camera: self.$camera.wrappedValue,
										 animated: false)
		mapView.locationManager = mapView.locationManager

		// Link the style loaded to the coordinator that emits the delegate event.
		context.coordinator.onStyleLoaded = self.onStyleLoaded

		// Add all gesture recognizers
		for gesture in self.gestures {
			registerGesture(mapView, context, gesture: gesture)
		}

		return mapView
	}

	public func updateUIView(_ mapView: NavigationMapView, context: Context) {
		context.coordinator.parent = self

		self.applyModifiers(mapView, runUnsafe: true)

		// FIXME: This should be a more selective update
		context.coordinator.updateStyleSource(self.styleSource, mapView: mapView)
		context.coordinator.updateLayers(mapView: mapView)

		// FIXME: This isn't exactly telling us if the *map* is loaded, and the docs for setCenter say it needs to be.
		let isStyleLoaded = mapView.style != nil

		context.coordinator.updateCamera(mapView: mapView,
										 camera: self.$camera.wrappedValue,
										 animated: isStyleLoaded)
	}

	// MARK: - Private

	@MainActor private func applyModifiers(_ mapView: NavigationMapView, runUnsafe: Bool) {
		mapView.contentInset = self.mapViewContentInset

		// Assume all controls are hidden by default (so that an empty list returns a map with no controls)
		mapView.logoView.isHidden = true
		mapView.compassView.isHidden = true
		mapView.attributionButton.isHidden = true

		// Apply each control configuration
		for control in self.controls {
			control.configureMapView(mapView)
		}

		if runUnsafe {
			self.unsafeMapViewModifier?(mapView)
		}
	}

}

// MARK: - MapViewCoordinator

public class MapViewCoordinator: NSObject {
	// This must be weak, the UIViewRepresentable owns the MLNMapView.
	weak var mapView: NavigationMapView?
	var parent: NavigationView

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

	init(parent: NavigationView,
		 onGesture: @escaping (NavigationMapView, UIGestureRecognizer) -> Void,
		 onViewPortChanged: @escaping (MapViewPort) -> Void) {
		self.parent = parent
		self.onGesture = onGesture
		self.onViewPortChanged = onViewPortChanged
	}

	// MARK: - Internal

	// MARK: Core UIView Functionality

	@objc func captureGesture(_ sender: UIGestureRecognizer) {
		guard let mapView else {
			return
		}

		self.onGesture(mapView, sender)
	}

	// MARK: - Coordinator API - Camera + Manipulation

	/// Update the camera based on the MapViewCamera binding change.
	///
	/// - Parameters:
	///   - mapView: This is the camera updating protocol representation of the MLNMapView. This allows mockable testing
	/// for
	/// camera related MLNMapView functionality.
	///   - camera: The new camera from the binding.
	///   - animated: Whether to animate.
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

	// MARK: - Coordinator API - Styles + Layers

	@MainActor func updateStyleSource(_ source: MapStyleSource, mapView: NavigationMapView) {
		switch (source, self.snapshotStyleSource) {
		case let (.url(newURL), .url(oldURL)):
			if newURL != oldURL {
				mapView.styleURL = newURL
			}
		case let (.url(newURL), .none):
			mapView.styleURL = newURL
		}

		self.snapshotStyleSource = source
	}

	@MainActor func updateLayers(mapView: NavigationMapView) {
		// TODO: Figure out how to selectively update layers when only specific props changed. New function in addition to makeMLNStyleLayer?

		// TODO: Extract this out into a separate function or three...
		// Try to reuse DSL-defined sources if possible (they are the same type)!
		if let style = mapView.style {
			var sourcesToRemove = Set<String>()
			for layer in self.snapshotUserLayers {
				if let oldLayer = style.layer(withIdentifier: layer.identifier) {
					style.removeLayer(oldLayer)
				}

				if let specWithSource = layer as? SourceBoundStyleLayerDefinition {
					switch specWithSource.source {
					case .mglSource:
						// Do Nothing
						// DISCUSS: The idea is to exclude "unmanaged" sources and only manage the ones specified via the DSL and attached to a layer.
						// This is a really hackish design and I don't particularly like it.
						continue
					case .source:
						// Mark sources for removal after all user layers have been removed.
						// Sources specified in this way should be used by a layer already in the style.
						sourcesToRemove.insert(specWithSource.source.identifier)
					}
				}
			}

			// Remove sources that were added by layers specified in the DSL
			for sourceID in sourcesToRemove {
				if let source = style.source(withIdentifier: sourceID) {
					style.removeSource(source)
				} else {
					print("That's funny... couldn't find identifier \(sourceID)")
				}
			}
		}

		// Snapshot the new user-defined layers
		self.snapshotUserLayers = self.parent.userLayers

		// If the style is loaded, add the new layers to it.
		// Otherwise, this will get invoked automatically by the style didFinishLoading callback
		if let style = mapView.style {
			self.addLayers(to: style)
		}
	}

	func addLayers(to mglStyle: MLNStyle) {
		for layerSpec in self.parent.userLayers {
			// DISCUSS: What preventions should we try to put in place against the user accidentally adding the same layer twice?
			let newLayer = layerSpec.makeStyleLayer(style: mglStyle).makeMLNStyleLayer()

			// Unconditionally transfer the common properties
			newLayer.isVisible = layerSpec.isVisible

			if let minZoom = layerSpec.minimumZoomLevel {
				newLayer.minimumZoomLevel = minZoom
			}

			if let maxZoom = layerSpec.maximumZoomLevel {
				newLayer.maximumZoomLevel = maxZoom
			}

			switch layerSpec.insertionPosition {
			case let .above(layerID: id):
				if let layer = mglStyle.layer(withIdentifier: id) {
					mglStyle.insertLayer(newLayer, above: layer)
				} else {
					NSLog("Failed to find layer with ID \(id). Adding layer on top.")
					mglStyle.addLayer(newLayer)
				}
			case let .below(layerID: id):
				if let layer = mglStyle.layer(withIdentifier: id) {
					mglStyle.insertLayer(newLayer, below: layer)
				} else {
					NSLog("Failed to find layer with ID \(id). Adding layer on top.")
					mglStyle.addLayer(newLayer)
				}
			case .aboveOthers:
				mglStyle.addLayer(newLayer)
			case .belowOthers:
				mglStyle.insertLayer(newLayer, at: 0)
			}
		}
	}
}

// MARK: - MLNMapViewDelegate

extension MapViewCoordinator: MLNMapViewDelegate {
	public func mapView(_: MLNMapView, didFinishLoading mglStyle: MLNStyle) {
		self.addLayers(to: mglStyle)
		self.onStyleLoaded?(mglStyle)
	}

	// MARK: MapViewCamera

	@MainActor private func updateParentCamera(mapView: MLNMapView, reason: MLNCameraChangeReason) {
		// If any of these are a mismatch, we know the camera is no longer following a desired method, so we should
		// detach and revert to a .centered camera. If any one of these is true, the desired camera state still
		// matches the mapView's userTrackingMode
		// NOTE: The use of assumeIsolated is just to make Swift strict concurrency checks happy.
		// This invariant is upheld by the MLNMapView.
		let userTrackingMode = mapView.userTrackingMode
		let isProgrammaticallyTracking: Bool = switch self.parent.camera.state {
		case .trackingUserLocation:
			userTrackingMode == .follow
		case .trackingUserLocationWithHeading:
			userTrackingMode == .followWithHeading
		case .trackingUserLocationWithCourse:
			userTrackingMode == .followWithCourse
		case .centered, .rect, .showcase:
			false
		}

		guard !isProgrammaticallyTracking else {
			// Programmatic tracking is still active, we can ignore camera updates until we unset/fail this boolean
			// check
			return
		}

		// Publish the MLNMapView's "raw" camera state to the MapView camera binding.
		// This path only executes when the map view diverges from the parent state, so this is a "matter of fact"
		// state propagation.
		let newCamera: MapViewCamera = .center(mapView.centerCoordinate,
											   zoom: mapView.zoomLevel,
											   // TODO: Pitch doesn't really describe current state
											   pitch: .freeWithinRange(
											   	minimum: mapView.minimumPitch,
											   	maximum: mapView.maximumPitch
											   ),
											   direction: mapView.direction,
											   reason: CameraChangeReason(reason))
		self.snapshotCamera = newCamera
		self.parent.camera = newCamera
	}

	/// The MapView's region has changed with a specific reason.
	public func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated _: Bool) {
		// FIXME: CI complains about MainActor.assumeIsolated being unavailable before iOS 17, despite building on iOS 17.2... This is an epic hack to fix it for now. I can only assume this is an issue with Xcode pre-15.3
		// TODO: We could put this in regionIsChangingWith if we calculate significant change/debounce.
		Task { @MainActor in
			self.updateViewPort(mapView: mapView, reason: reason)
		}

		guard !self.suppressCameraUpdatePropagation else {
			return
		}

		// FIXME: CI complains about MainActor.assumeIsolated being unavailable before iOS 17, despite building on iOS 17.2... This is an epic hack to fix it for now. I can only assume this is an issue with Xcode pre-15.3
		Task { @MainActor in
			self.updateParentCamera(mapView: mapView, reason: reason)
		}
	}

	// MARK: MapViewPort

	@MainActor private func updateViewPort(mapView: MLNMapView, reason: MLNCameraChangeReason) {
		// Calculate the Raw "ViewPort"
		let calculatedViewPort = MapViewPort(
			center: mapView.centerCoordinate,
			zoom: mapView.zoomLevel,
			direction: mapView.direction,
			lastReasonForChange: CameraChangeReason(reason)
		)

		self.onViewPortChanged(calculatedViewPort)
	}
}

extension NavigationView {
	/// Register a gesture recognizer on the MapView.
	///
	/// - Parameters:
	///   - mapView: The MLNMapView that will host the gesture itself.
	///   - context: The UIViewRepresentable context that will orchestrate the response sender
	///   - gesture: The gesture definition.
	@MainActor func registerGesture(_ mapView: MLNMapView, _ context: Context, gesture: MapGesture) {
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

	/// Runs on each gesture change event and filters the appropriate gesture behavior based on the
	/// user definition.
	///
	/// Since the gestures run "onChange", we run this every time, event when state changes. The implementer is
	/// responsible for
	/// guarding
	/// and handling whatever state logic they want.
	///
	/// - Parameters:
	///   - mapView: The MapView emitting the gesture. This is used to calculate the point and coordinate of the
	/// gesture.
	///   - sender: The UIGestureRecognizer
	@MainActor func processGesture(_ mapView: MLNMapView, _ sender: UIGestureRecognizer) {
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

	/// Convert the sender data into a MapGestureContext
	///
	/// - Parameters:
	///   - mapView: The mapview that's emitting the gesture.
	///   - gesture: The gesture definition for this event.
	///   - sender: The UIKit gesture emitting from the map view.
	/// - Returns: The calculated context from the sending UIKit gesture
	@MainActor func processContextFromGesture(_ mapView: MLNMapView, gesture: MapGesture,
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

extension NavigationView {
	/// Perform an action when the map view has loaded its style and all locally added style definitions.
	///
	/// - Parameter perform: The action to perform with the loaded style.
	/// - Returns: The modified map view.
	func onStyleLoaded(_ perform: @escaping (MLNStyle) -> Void) -> NavigationView {
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
	func unsafeMapViewModifier(_ modifier: @escaping (MLNMapView) -> Void) -> NavigationView {
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
						 onTapChanged: @escaping (MapGestureContext) -> Void) -> NavigationView {
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
						 onTapChanged: @escaping (MapGestureContext, [any MLNFeature]) -> Void) -> NavigationView {
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
							   onPressChanged: @escaping (MapGestureContext) -> Void) -> NavigationView {
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
