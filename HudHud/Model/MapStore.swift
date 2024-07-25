//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftLocation
import SwiftUI

// MARK: - MapStore

@MainActor
final class MapStore: ObservableObject {

    enum TrackingState {
        case none
        case locateOnce
        case keepTracking
    }

    enum NavigationProgress {
        case none
        case navigating
        case feedback
    }

    enum StreetViewOption: Equatable {
        case disabled
        case requestedCurrentLocation
        case enabled
    }

    enum CameraUpdateState {
        case route(RoutingService.RouteCalculationResult?)
        case selectedItem(ResolvedItem)
        case userLocation(CLLocationCoordinate2D)
        case mapItems
        case defaultLocation
    }

    var locationManager: Location = .forSingleRequestUsage
    let motionViewModel: MotionViewModel
    var moveToUserLocation = false

    @Published var styleURL: URL = .init(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")!
    @AppStorage("mapStyleURL") private var mapStyleURLString: String?

    @Published var camera: MapViewCamera = .center(.riyadh, zoom: 10, pitch: 0, pitchRange: .fixed(0))
    @Published var searchShown: Bool = true
    @Published var streetView: StreetViewOption = .disabled
    @Published var selectedDetent: PresentationDetent = .small
    @Published var allowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    @Published var waypoints: [ABCRouteConfigurationItem]?
    @Published var navigationProgress: NavigationProgress = .none
    @Published var trackingState: TrackingState = .none

    var hudhudStreetView = HudhudStreetView()
    @Published var street360View: Bool = false
    @Published var streetViewScene: StreetViewScene?

    @Published var navigatingRoute: Route? {
        didSet {
            if let elements = try? path.elements() {
                print("path now: \(elements)")
                self.updateSelectedSheetDetent(to: elements.last)
            }
        }
    }

    @Published var routes: RoutingService.RouteCalculationResult? {
        didSet {
            if let routes, self.path.contains(RoutingService.RouteCalculationResult.self) == false {
                self.path.append(routes)
                self.cameraTask?.cancel()
                self.cameraTask = Task {
                    try await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
                    try Task.checkCancellation()
                    await MainActor.run {
                        updateCamera(state: .route(self.routes))
                    }
                }
            }
        }
    }

    @Published var currentLocation: CLLocationCoordinate2D? {
        didSet {
            self.moveToUserLocation = true
            if let currentLocation {
                updateCamera(state: .userLocation(currentLocation))
            }
        }
    }

    @Published var path = NavigationPath() {
        didSet {
            self.updateDetent()
        }
    }

    @Published var displayableItems: [DisplayableRow] = [] {
        didSet {
            guard self.displayableItems != [] else { return }

            self.updateDetent()
            self.updateCamera(state: .mapItems)
        }
    }

    @Published var selectedItem: ResolvedItem? {
        didSet {
            if let selectedItem, routes == nil {
                self.updateCamera(state: .selectedItem(selectedItem))
                if self.path.isEmpty {
                    self.path.append(selectedItem)
                } else {
                    self.path.removeLast()
                    self.path.append(selectedItem)
                }
            } else {
                return
            }
        }
    }

    var mapItems: [ResolvedItem] {
        let allItems = Set(self.displayableItems)

        if let selectedItem {
            let items = allItems.union([DisplayableRow.resolvedItem(selectedItem)])
            return items.compactMap(\.resolvedItem)
        }

        return self.displayableItems.compactMap(\.resolvedItem)
    }

    var points: ShapeSource {
        return ShapeSource(identifier: MapSourceIdentifier.points, options: [.clustered: true, .clusterRadius: 44]) {
            self.mapItems.compactMap { item in
                return MLNPointFeature(coordinate: item.coordinate) { feature in
                    feature.attributes["poi_id"] = item.id
                }
            }
        }
    }

    var routePoints: ShapeSource {
        var features: [MLNPointFeature] = []
        if let waypoints = self.waypoints {
            for item in waypoints {
                switch item {
                case .myLocation:
                    continue
                case let .waypoint(poi):
                    let feature = MLNPointFeature(coordinate: poi.coordinate)
                    feature.attributes["poi_id"] = poi.id
                    features.append(feature)
                }
            }
        }
        return ShapeSource(identifier: MapSourceIdentifier.routePoints) {
            features
        }
    }

    var selectedPoint: ShapeSource {
        ShapeSource(identifier: MapSourceIdentifier.selectedPoint, options: [.clustered: false]) {
            if let selectedItem,
               mapItems.count > 1 {
                let feature = MLNPointFeature(coordinate: selectedItem.coordinate)
                feature.attributes["poi_id"] = selectedItem.id
                feature
            }
        }
    }

    var streetViewSource: ShapeSource {
        ShapeSource(identifier: MapSourceIdentifier.streetViewSymbols) {
            if case .enabled = self.streetView, let coordinate = self.motionViewModel.coordinate {
                let streetViewPoint = StreetViewPoint(location: coordinate,
                                                      heading: self.motionViewModel.position.heading)
                streetViewPoint.feature
            }
        }
    }

    var cameraTask: Task<Void, Error>?

    // MARK: - Lifecycle

    init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, motionViewModel: MotionViewModel) {
        self.mapStyleURLString = ""
        self.camera = camera
        self.searchShown = searchShown
        self.motionViewModel = motionViewModel
    }

    // MARK: - Internal

    /**
     This function determines the appropriate sheet detent based on the current state of the map store and search text.

     Current Criteria:
     - If there are routes available or a selected item, the sheet detent is set to `.medium`.
     - If the search text is not empty, the sheet detent is set to `.medium`.
     - Otherwise, the sheet detent is set to `.small`.

     Important Note:
     This function relies on changes to the `mapStore.routes`, `mapStore.selectedItem`, and `searchText`. If additional criteria are added in the future (e.g., `mapItems`), ensure to:
     1. Update this function to include the new criteria.
     2. Set up the appropriate observers for the new criteria to call `updateSheetDetent`.

     Failure to do so can result in the function not updating the detent properly when the new criteria change.
     **/

    func updateSelectedSheetDetent(to navigationPathItem: Any?) {
        if self.navigatingRoute != nil {
            let closed: PresentationDetent = .height(0)
            self.allowedDetents = [closed]
            self.selectedDetent = closed
            return
        }

        // If routes exist or an item is selected, use the medium detent

        guard let navigationPathItem else {
            self.allowedDetents = [.small, .third, .large]
            if self.mapItems.isEmpty {
                self.selectedDetent = .small
            } else {
                self.selectedDetent = .third
            }
            return
        }

        if let sheetSubview = navigationPathItem as? SheetSubView {
            switch sheetSubview {
            case .mapStyle:
                self.allowedDetents = [.small, .medium]
                self.selectedDetent = .medium
            case .debugView:
                self.allowedDetents = [.large]
                self.selectedDetent = .large
            case .navigationAddSearchView:
                self.allowedDetents = [.large]
                self.selectedDetent = .large
            case .favorites:
                self.allowedDetents = [.large]
                self.selectedDetent = .large
            }
        }
        if navigationPathItem is ResolvedItem {
            self.allowedDetents = [.small, .third, .nearHalf, .large]
            self.selectedDetent = .nearHalf
        }
        if navigationPathItem is RoutingService.RouteCalculationResult {
            self.allowedDetents = [.height(150), .nearHalf]
            self.selectedDetent = .nearHalf
        }
    }

    func getCameraPitch() -> Double {
        if case let .centered(
            onCoordinate: _,
            zoom: _,
            pitch: pitch,
            pitchRange: _,
            direction: _
        ) = camera.state {
            return pitch
        }
        return 0
    }
}

// MARK: - NavigationViewControllerDelegate

extension MapStore: NavigationViewControllerDelegate {

    func navigationViewControllerDidFinishRouting(_: NavigationViewController) {
        self.navigatingRoute = nil
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        return navigationViewController.routeController?.userIsOnRoute(location) == false
    }

    func navigationViewController(_: NavigationViewController, willRerouteFrom location: CLLocation) {
        Task {
            do {
                guard let currentRoute = self.navigatingRoute?.routeOptions.waypoints.last else { return }
                let options = NavigationRouteOptions(waypoints: [Waypoint(location: location), currentRoute])

                options.shapeFormat = .polyline6
                options.distanceMeasurementSystem = .metric
                options.attributeOptions = []

                let results = try await RoutingService.shared.calculate(host: DebugStore().routingHost, options: options)
                if let route = results.routes.first {
                    await self.reroute(with: route)
                }
            } catch {
                Logger.routing.error("Updating routes failed\(error.localizedDescription)")
            }
        }
    }

    func navigationViewController(_: NavigationViewController, didFailToRerouteWith error: any Error) {
        Logger.routing.error("Failed to reroute: \(error.localizedDescription)")
    }

    func navigationViewController(_: NavigationViewController, didRerouteAlong route: Route) {
        self.navigatingRoute = route
        Logger.routing.info("didRerouteAlong new route \(route)")
    }
}

extension MapStore {

    func loadStreetViewScene(id: Int, block: ((_ item: StreetViewScene?) -> Void)?) {
        Task {
            do {
                if let streetViewScene = try await hudhudStreetView.getStreetViewScene(id: id) {
                    print(streetViewScene)
                    self.streetViewScene = streetViewScene
                    self.street360View = true
                    block?(streetViewScene)
                }
            } catch {
                print("error \(error)")
            }
        }
    }

}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing)
}

// MARK: - Private

private extension MapStore {

    func generateMLNCoordinateBounds(from coordinates: [CLLocationCoordinate2D]) -> MLNCoordinateBounds? {
        guard !coordinates.isEmpty else {
            return nil
        }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            if coordinate.latitude < minLat {
                minLat = coordinate.latitude
            }
            if coordinate.latitude > maxLat {
                maxLat = coordinate.latitude
            }
            if coordinate.longitude < minLon {
                minLon = coordinate.longitude
            }
            if coordinate.longitude > maxLon {
                maxLon = coordinate.longitude
            }
        }

        let southWest = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
        let northEast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)

        return MLNCoordinateBounds(sw: southWest, ne: northEast)
    }

    func updateCamera(state: CameraUpdateState) {
        switch state {
        // show the whole route on the map
        case let .route(result):
            if let routes = result?.routes {
                if let route = routes.first,
                   let coordinates = route.coordinates,
                   coordinates.hasElements,
                   let boundingBox = self.generateMLNCoordinateBounds(from: coordinates) {
                    self.camera = MapViewCamera.boundingBox(boundingBox,
                                                            edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 60, right: 40))
                }
                return
            }
        case let .selectedItem(selectedItem):
            // if the item selected from multi-map items(nearby poi), the camera will not move
            // Hint: the pin should animate or change the color of it. no camera move need it
            if let bounds = mapItems.map(\.coordinate).boundingBox(),
               bounds.contains(coordinate: selectedItem.coordinate),
               mapItems.count > 1, !isAnyItemVisible() {
                let coordinates = self.mapItems.map(\.coordinate)
                if let camera = CameraState.boundingBox(from: coordinates) {
                    self.camera = camera
                }
            } else {
                if self.mapItems.count > 1 {
                    // do not show any move
                    if let zoom = self.camera.zoom {
                        self.camera.setZoom(zoom)
                    }
                } else {
                    // if poi choosing from Resents or directly from the search it will zoom and center around it
                    self.camera = .center(selectedItem.coordinate, zoom: 15)
                }
            }
        case let .userLocation(userLocation):
            self.moveToUserLocation = false
            self.camera = MapViewCamera.center(userLocation, zoom: 14)

        case .mapItems:
            Task {
                await self.handleMapItems()
            }
        default:
            self.camera = MapViewCamera.center(.riyadh, zoom: 16)
        }
    }

    func updateDetent() {
        do {
            let elements = try path.elements()
            print("path now: \(elements)")
            self.updateSelectedSheetDetent(to: elements.last)
        } catch {
            print("update detent error: \(error)")
        }
    }

    func handleMapItems() async {
        switch self.mapItems.count {
        case 0:
            break // no items, do nothing
        case 1:
            // if there is only one item ...center around this location
            if let item = mapItems.first, routes == nil {
                self.camera = .center(item.coordinate, zoom: 16)
            }
        case 2...:
            // if there is more than 2 items on the map ...and the zoom level is under 13 ...zoom out and move the camera to show items
            if (self.camera.zoom ?? 0) <= 13 {
                var coordinates = self.mapItems.map(\.coordinate)
                if let userLocation = try? await self.locationManager.requestLocation().location?.coordinate {
                    coordinates.append(userLocation)
                }
                if let camera = CameraState.boundingBox(from: coordinates) {
                    self.camera = camera
                }
            } else {
                // if the camera zooming in...zoom out a little bit and show the nearest 4 poi around me
                if self.isAnyItemVisible() || (self.camera.zoom ?? 0) >= 13 {
                    if let nearestCoordinates = await getNearestMapItemCoordinates() {
                        var coordinatea = nearestCoordinates
                        if let userLocation = try? await self.locationManager.requestLocation().location?.coordinate {
                            coordinatea.append(userLocation)
                        }
                        if let camera = CameraState.boundingBox(from: coordinatea) {
                            self.camera = camera
                        }
                    }
                } else {
                    // do not show any move
                    if let zoom = self.camera.zoom {
                        self.camera.setZoom(zoom)
                    }
                }
            }
        default:
            break // should never occur
        }
    }

    func reroute(with route: Route) async {
        self.navigatingRoute = route
    }

    func getCameraCoordinate() -> CLLocationCoordinate2D {
        if case let .centered(
            onCoordinate: onCoordinate,
            zoom: _,
            pitch: _,
            pitchRange: _,
            direction: _
        ) = camera.state {
            return onCoordinate
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    // check if the there is an item on the Coordinate of the Camera on the map
    func isAnyItemVisible() -> Bool {
        if let bounds = self.mapItems.map(\.coordinate).boundingBox() {
            return bounds.contains(coordinate: self.getCameraCoordinate())
        }
        return false
    }

    func getNearestMapItemCoordinates() async -> [CLLocationCoordinate2D]? {
        guard let userLocation = try? await self.locationManager.requestLocation().location?.coordinate else { return nil }
        // Sort map items by distance to the user location
        let sortedItems = self.mapItems.sorted(by: {
            $0.coordinate.distance(to: userLocation) < $1.coordinate.distance(to: userLocation)
        })
        // Return the coordinates of the 4 nearest items, if available
        return Array(sortedItems.prefix(4)).map(\.coordinate)
    }
}

extension [CLLocationCoordinate2D] {

    func boundingBox() -> MLNCoordinateBounds? {
        guard let first = self.first else { return nil }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in self {
            if coordinate.latitude < minLat {
                minLat = coordinate.latitude
            }
            if coordinate.latitude > maxLat {
                maxLat = coordinate.latitude
            }
            if coordinate.longitude < minLon {
                minLon = coordinate.longitude
            }
            if coordinate.longitude > maxLon {
                maxLon = coordinate.longitude
            }
        }

        return MLNCoordinateBounds(sw: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
                                   ne: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon))
    }
}

extension MLNCoordinateBounds {

    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= self.sw.latitude &&
            coordinate.latitude <= self.ne.latitude &&
            coordinate.longitude >= self.sw.longitude &&
            coordinate.longitude <= self.ne.longitude
    }
}
