import FerrostarCore
import FerrostarSwiftUI
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - LandscapeNavigationView

/// A landscape orientation navigation view that includes the InstructionsView and ArrivalView on the
/// leading half of the screen.
public struct LandscapeNavigationView<T: MapViewHostViewController>: View, CustomizableNavigatingInnerGridView, SpeedLimitViewHost {

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

//    @State var speedLimit: Measurement<UnitSpeed>?

    let makeViewController: () -> T
    let isMuted: Bool
    let onTapMute: () -> Void
    var onTapExit: (() -> Void)?

    private var navigationState: NavigationState?
    private let userLayers: [StyleLayerDefinition]

    // MARK: Lifecycle

    /// Create a landscape navigation view. This view is optimized for display on a landscape screen where the
    /// instructions are on the leading half of the screen
    /// and the user puck and route are on the trailing half of the screen.
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
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    public init(
        makeViewController: @escaping @autoclosure () -> T,
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        navigationState: NavigationState?,
        isMuted: Bool,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] }
    ) {
        self.makeViewController = makeViewController
        self.styleURL = styleURL
        self.navigationState = navigationState
        self.isMuted = isMuted
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapMute = onTapMute
        self.onTapExit = onTapExit

        self.userLayers = makeMapContent()
        _camera = camera
        self.navigationCamera = navigationCamera
    }

    // MARK: Content

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationMapView(
                    makeViewController: self.makeViewController(),
                    styleURL: self.styleURL,
                    camera: self.$camera,
                    navigationState: self.navigationState,
                    onStyleLoaded: { _ in
                        self.camera = self.navigationCamera
                    }
                ) {
                    self.userLayers
                }
                .navigationMapViewContentInset(.landscape(within: geometry))

                LandscapeNavigationOverlayView(
                    navigationState: self.navigationState,
                    speedLimit: self.speedLimit,
                    isMuted: self.isMuted,
                    showMute: true,
                    onMute: self.onTapMute,
                    showZoom: true,
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
            }
        }
    }
}

public extension LandscapeNavigationView where T == MLNMapViewController {
    /// Create a landscape navigation view. This view is optimized for display on a landscape screen where the
    /// instructions are on the leading half of the screen
    /// and the user puck and route are on the trailing half of the screen.
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
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    init(
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        navigationState: NavigationState?,
        isMuted: Bool,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] }
    ) {
        self.makeViewController = MLNMapViewController.init
        self.styleURL = styleURL
        self.navigationState = navigationState
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapExit = onTapExit
        self.userLayers = makeMapContent()
        _camera = camera
        self.navigationCamera = navigationCamera
        self.isMuted = isMuted
        self.onTapMute = onTapMute
    }
}

//
// @available(iOS 17, *)
// #Preview("Landscape Navigation View (Imperial)", traits: .landscapeLeft) {
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
//    return LandscapeNavigationView(
//        styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!,
//        camera: .constant(.center(userLocation.clLocation.coordinate, zoom: 12)),
//        navigationState: state,
//        isMuted: true,
//        onTapMute: {}
//    )
//    .navigationFormatterCollection(FoundationFormatterCollection(distanceFormatter: formatter))
// }
//
// @available(iOS 17, *)
// #Preview("Landscape Navigation View (Metric)", traits: .landscapeLeft) {
//    // TODO: Make map URL configurable but gitignored
//    let state = NavigationState.modifiedPedestrianExample(droppingNWaypoints: 4)
//
//    let formatter = MKDistanceFormatter()
//    formatter.locale = Locale(identifier: "en-US")
//    formatter.units = .metric
//
//    guard case let .navigating(_, snappedUserLocation: userLocation, _, _, _, _, _, _, _) = state.tripState else {
//        return EmptyView()
//    }
//
//    return LandscapeNavigationView(
//        styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!,
//        camera: .constant(.center(userLocation.clLocation.coordinate, zoom: 12)),
//        navigationState: state,
//        isMuted: true,
//        onTapMute: {}
//    )
//    .navigationFormatterCollection(FoundationFormatterCollection(distanceFormatter: formatter))
// }
