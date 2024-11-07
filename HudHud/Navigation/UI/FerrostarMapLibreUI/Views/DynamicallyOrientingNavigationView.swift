import FerrostarCore
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - DynamicallyOrientingNavigationView

/// A navigation view that dynamically switches between portrait and landscape orientations.
public struct DynamicallyOrientingNavigationView<T: MapViewHostViewController>: View, CustomizableNavigatingInnerGridView, SpeedLimitViewHost, NavigationOverlayContent {

    // MARK: Properties

    public var speedLimit: Measurement<UnitSpeed>?

    public var topCenter: (() -> AnyView)?
    public var topTrailing: (() -> AnyView)?
    public var midLeading: (() -> AnyView)?
    public var bottomTrailing: (() -> AnyView)?
    public var bottomLeading: (() -> AnyView)?

    public var minimumSafeAreaInsets: EdgeInsets

    @State public var overlayStore = OverlayContentStore()

    @Environment(\.navigationFormatterCollection) var formatterCollection: any FormatterCollection

    let styleURL: URL
    @Binding var camera: MapViewCamera
    let navigationCamera: MapViewCamera

    let isMuted: Bool
    let showZoom: Bool

    let onTapMute: () -> Void
    let makeViewController: () -> T

    @State private var orientation = UIDevice.current.orientation

    private let userLayers: () -> [StyleLayerDefinition]

    private let mapViewModifiers: (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T>

    private let locationManager: PassthroughLocationManager

    private let isNavigating: Bool

    // MARK: Lifecycle

    public init(
        makeViewController: @autoclosure @escaping () -> T,
        locationManager: PassthroughLocationManager,
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        isNavigating: Bool,
        isMuted: Bool,
        showZoom: Bool,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTapMute: @escaping () -> Void,
        @MapViewContentBuilder makeMapContent: @escaping () -> [StyleLayerDefinition] = { [] },
        mapViewModifiers: @escaping (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T> = { transferView, _ in
            transferView
        }
    ) {
        self.makeViewController = makeViewController
        self.locationManager = locationManager
        self.styleURL = styleURL
        self.isNavigating = isNavigating
        self.isMuted = isMuted
        self.showZoom = showZoom
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapMute = onTapMute
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
                    isNavigating: self.isNavigating,
                    onStyleLoaded: { _ in
                        if self.isNavigating {
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
                        overlayStore: self.overlayStore,
                        speedLimit: self.speedLimit,
                        isMuted: self.isMuted,
                        showMute: self.isNavigating == true,
                        onMute: self.onTapMute,
                        showZoom: self.showZoom,
                        onZoomIn: { self.camera.incrementZoom(by: 1) },
                        onZoomOut: { self.camera.incrementZoom(by: -1) },
                        showCentering: !self.camera.isTrackingUserLocationWithCourse,
                        onCenter: { self.camera = self.navigationCamera }
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
                        overlayStore: self.overlayStore,
                        speedLimit: self.speedLimit,
                        isMuted: self.isMuted,
                        showMute: self.isNavigating == true,
                        onMute: self.onTapMute,
                        showZoom: self.showZoom,
                        onZoomIn: { self.camera.incrementZoom(by: 1) },
                        onZoomOut: { self.camera.incrementZoom(by: -1) },
                        showCentering: !self.camera.isTrackingUserLocationWithCourse,
                        onCenter: { self.camera = self.navigationCamera }
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
    }
}
