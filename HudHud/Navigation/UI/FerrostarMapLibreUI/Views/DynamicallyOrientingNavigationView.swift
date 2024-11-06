import FerrostarCore
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - DynamicallyOrientingNavigationView

/// A navigation view that dynamically switches between portrait and landscape orientations.
public struct DynamicallyOrientingNavigationView<T: MapViewHostViewController>: View, CustomizableNavigatingInnerGridView, SpeedLimitViewHost {

    // MARK: Properties

    public var speedLimit: Measurement<UnitSpeed>?

    public var topCenter: (() -> AnyView)?
    public var topTrailing: (() -> AnyView)?
    public var midLeading: (() -> AnyView)?
    public var bottomTrailing: (() -> AnyView)?
    public var bottomLeading: (() -> AnyView)?

    public var minimumSafeAreaInsets: EdgeInsets

    @Environment(\.navigationFormatterCollection) var formatterCollection: any FormatterCollection

    let styleURL: URL
    @Binding var camera: MapViewCamera
    let navigationCamera: MapViewCamera

    let isMuted: Bool
    let showZoom: Bool

    let onTapMute: () -> Void
    var onTapExit: (() -> Void)?
    let makeViewController: () -> T

    @State private var orientation = UIDevice.current.orientation

    private var navigationState: NavigationState?

    private let userLayers: () -> [StyleLayerDefinition]

    private let mapViewModifiers: (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T>

    private let locationManager: PassthroughLocationManager

    // MARK: Lifecycle

    /// Create a dynamically orienting navigation view. This view automatically arranges child views for both portrait
    /// and landscape orientations.
    ///
    /// - Parameters:
    ///   - styleURL: The map's style url.
    ///   - camera: The camera binding that represents the current camera on the map.
    ///   - navigationCamera: The default navigation camera. This sets the initial camera & is also used when the center
    ///         on user button it tapped.
    ///   - navigationState: The current ferrostar navigation state provided by the Ferrostar core.
    ///   - minimumSafeAreaInsets: The minimum padding to apply from safe edges. See `complementSafeAreaInsets`.
    ///   - onTapExit: An optional behavior to run when the ArrivalView exit button is tapped. When nil (default) the
    ///         exit button is hidden.
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    public init(
        makeViewController: @autoclosure @escaping () -> T,
        locationManager: PassthroughLocationManager,
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        navigationState: NavigationState?,
        isMuted: Bool,
        showZoom: Bool,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: @escaping () -> [StyleLayerDefinition] = { [] },
        mapViewModifiers: @escaping (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T> = { transferView, _ in
            transferView
        }
    ) {
        self.makeViewController = makeViewController
        self.locationManager = locationManager
        self.styleURL = styleURL
        self.navigationState = navigationState
        self.isMuted = isMuted
        self.showZoom = showZoom
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapMute = onTapMute
        self.onTapExit = onTapExit
        self.mapViewModifiers = mapViewModifiers
        self.userLayers = makeMapContent
        self._camera = camera
        self.navigationCamera = navigationCamera
    }

    // MARK: Content

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationMapView(
                    makeViewController: self.makeViewController(),
                    locationManager: self.locationManager,
                    styleURL: self.styleURL,
                    camera: self.$camera,
                    navigationState: self.navigationState,
                    onStyleLoaded: { _ in
                        if self.navigationState?.isNavigating == true {
                            self.camera = self.navigationCamera
                        }
                    },
                    makeMapContent: self.userLayers,
                    mapViewModifiers: self.mapViewModifiers
                )
                .navigationMapViewContentInset(NavigationMapViewContentInsetMode(
                    orientation: self.orientation,
                    geometry: geometry
                ))

                switch self.orientation {
                case .landscapeLeft, .landscapeRight:
                    LandscapeNavigationOverlayView(
                        navigationState: self.navigationState,
                        speedLimit: self.speedLimit,
                        isMuted: self.isMuted,
                        showMute: self.navigationState?.isNavigating == true,
                        onMute: self.onTapMute,
                        showZoom: self.showZoom,
                        onZoomIn: { self.camera.incrementZoom(by: 1) },
                        onZoomOut: { self.camera.incrementZoom(by: -1) },
                        showCentering: !self.camera.isTrackingUserLocationWithCourse,
                        onCenter: { self.camera = self.navigationCamera },
                        onTapExit: self.onTapExit
                    )
                    .innerGrid {
                        self.topCenter?()
                    } topTrailing: {
                        self.topTrailing?()
                    } midLeading: {
                        self.midLeading?()
                    } bottomTrailing: {
                        self.bottomTrailing?()
                    }.complementSafeAreaInsets(parentGeometry: geometry, minimumInsets: self.minimumSafeAreaInsets)
                default:
                    PortraitNavigationOverlayView(
                        navigationState: self.navigationState,
                        speedLimit: self.speedLimit,
                        isMuted: self.isMuted,
                        showMute: self.navigationState?.isNavigating == true,
                        onMute: self.onTapMute,
                        showZoom: self.showZoom,
                        onZoomIn: { self.camera.incrementZoom(by: 1) },
                        onZoomOut: { self.camera.incrementZoom(by: -1) },
                        showCentering: !self.camera.isTrackingUserLocationWithCourse,
                        onCenter: { self.camera = self.navigationCamera },
                        onTapExit: self.onTapExit
                    )
                    .innerGrid {
                        self.topCenter?()
                    } topTrailing: {
                        self.topTrailing?()
                    } midLeading: {
                        self.midLeading?()
                    } bottomTrailing: {
                        self.bottomTrailing?()
                    } bottomLeading: {
                        self.bottomLeading?()
                    }
                    .complementSafeAreaInsets(parentGeometry: geometry, minimumInsets: self.minimumSafeAreaInsets)
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        ) { _ in
            self.orientation = UIDevice.current.orientation
        }

//        .onChange(of: navigationState) { value in
//                  speedLimit = calculateSpeedLimit?(value)
//              }
    }
}

public extension DynamicallyOrientingNavigationView where T == MLNMapViewController {
    /// Create a dynamically orienting navigation view. This view automatically arranges child views for both portait
    /// and landscape orientations.
    ///
    /// - Parameters:
    ///   - styleURL: The map's style url.
    ///   - camera: The camera binding that represents the current camera on the map.
    ///   - navigationCamera: The default navigation camera. This sets the initial camera & is also used when the center
    /// on user button it tapped.
    ///   - navigationState: The current ferrostar navigation state provided by the Ferrostar core.
    ///   - minimumSafeAreaInsets: The minimum padding to apply from safe edges. See `complementSafeAreaInsets`.
    ///   - onTapExit: An optional behavior to run when the ArrivalView exit button is tapped. When nil (default) the
    /// exit button is hidden.
    ///   - makeMapContent: Custom maplibre layers to display on the map view.
    ///   - mapViewModifiers: An optional closure that allows you to apply custom view and map modifiers to the `MapView`. The closure
    ///     takes the `MapView` instance and provides a Boolean indicating if navigation is active, and returns an `AnyView`. Use this to attach onMapTapGesture and other view modifiers to the underlying MapView and customize when the modifiers are applied using
    ///       the isNavigating modifier.
    ///     By default, it returns the unmodified `MapView`.
    init(
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        locationManager: PassthroughLocationManager,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        navigationState: NavigationState?,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        showZoom: Bool,
        isMuted: Bool,
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: @escaping () -> [StyleLayerDefinition] = { [] },
        mapViewModifiers: @escaping (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T> = { transferView, _ in
            transferView
        }
    ) {
        self.showZoom = showZoom
        self.makeViewController = MLNMapViewController.init
        self.locationManager = locationManager
        self.styleURL = styleURL
        self.navigationState = navigationState
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapExit = onTapExit
        self.userLayers = makeMapContent
        self._camera = camera
        self.navigationCamera = navigationCamera
        self.mapViewModifiers = mapViewModifiers
        self.isMuted = isMuted
        self.onTapMute = onTapMute
    }
}

// #Preview("Portrait Navigation View (Imperial)") {
//    // TODO: Make map URL configurable but gitignored
//    let state = NavigationState.modifiedPedestrianExample(droppingNWaypoints: 4)
//
//    let formatter = MKDistanceFormatter()
//    formatter.locale = Locale(identifier: "en-US")
//    formatter.units = .imperial
//
//    guard case let .navigating(_, snappedUserLocation: userLocation, _, _, _, _, _, _, _) = state.tripState else {
//        return EmptyView()
//    }
//
//    return DynamicallyOrientingNavigationView<MLNMapViewController>(
//        styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!,
//        camera: .constant(.center(userLocation.clLocation.coordinate, zoom: 12)),
//        navigationState: state,
//        isMuted: true,
//        onTapMute: {}
//    )
//    .navigationFormatterCollection(FoundationFormatterCollection(distanceFormatter: formatter))
// }
//
// #Preview("Portrait Navigation View (Metric)") {
//    // TODO: Make map URL configurable but gitignored
//    let state = NavigationState.modifiedPedestrianExample(droppingNWaypoints: 4)
//    let formatter = MKDistanceFormatter()
//    formatter.locale = Locale(identifier: "en-US")
//    formatter.units = .metric
//
//    guard case let .navigating(_, snappedUserLocation: userLocation, _, _, _, _, _, _, _) = state.tripState else {
//        return EmptyView()
//    }
//
//    return DynamicallyOrientingNavigationView<MLNMapViewController>(
//        styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!,
//        camera: .constant(.center(userLocation.clLocation.coordinate, zoom: 12)),
//        navigationState: state,
//        isMuted: true,
//        onTapMute: {}
//    )
//    .navigationFormatterCollection(FoundationFormatterCollection(distanceFormatter: formatter))
// }
