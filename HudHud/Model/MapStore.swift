//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
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

    enum CameraUpdateState {
        case route(RoutingService.RouteCalculationResult?)
        case selectedItem(ResolvedItem)
        case userLocation(CLLocationCoordinate2D)
        case mapItems
        case defaultLocation
    }

    let motionViewModel: MotionViewModel
    var mapStyle: MLNStyle?

    @AppStorage("mapStyleLayer") var mapStyleLayer: HudHudMapLayer?
    @Published var shouldShowCustomSymbols = false
    @Published var camera: MapViewCamera = .center(.riyadh, zoom: 10, pitch: 0, pitchRange: .fixed(0))
    @Published var searchShown: Bool = true
    @Published var selectedDetent: PresentationDetent = .small
    @Published var allowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    @Published var waypoints: [ABCRouteConfigurationItem]?
    @Published var navigationProgress: NavigationProgress = .none
    @Published var trackingState: TrackingState = .none

    var hudhudStreetView = HudhudStreetView()
    private let hudhudResolver = HudHudPOI()
    private var subscriptions: Set<AnyCancellable> = []
    @Published var streetViewScene: StreetViewScene?
    @Published var nearestStreetViewScene: StreetViewScene?
    @Published var fullScreenStreetView: Bool = false
    var cachedScenes = [Int: StreetViewScene]()
    var mapView: NavigationMapView?
    let userLocationStore: UserLocationStore

    @Published var navigatingRoute: Route? {
        didSet {
            if let elements = try? path.elements() {
                Logger.navigationPath.log("path now: \(elements)")
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
                    feature.attributes["ios_category_icon_name"] = item.symbol.rawValue
                    feature.attributes["ios_category_icon_color"] = item.systemColor.rawValue
                    feature.attributes["name"] = item.title
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
            if let selectedItem {
                let feature = MLNPointFeature(coordinate: selectedItem.coordinate)
                feature.attributes["poi_id"] = selectedItem.id
                feature
            }
        }
    }

    var cameraTask: Task<Void, Error>?

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
                self.allowedDetents = [.medium]
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

    func mapStyleUrl() -> URL {
        guard let styleUrl = self.mapStyleLayer?.styleUrl else {
            return URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping
        }
        return styleUrl
    }

    func focusOnUser() async {
        guard let location = self.userLocationStore.currentUserLocation?.coordinate else { return }
        withAnimation {
            updateCamera(state: .userLocation(location))
        }
    }

    func updateCurrentMapStyle(mapLayers: [HudHudMapLayer]) {
        // On first launch we use the first one returned and set it as default.
        if let mapLayer = self.mapStyleLayer {
            if !mapLayers.contains(mapLayer) {
                // The currently used style is not included in the map layers from the server
                if let firstLayer = mapLayers.first {
                    self.mapStyleLayer = firstLayer
                } else {
                    // Handle the case where mapLayers is empty if needed
                    Logger().error("No available map layers from the server.")
                }
            }
        } else {
            // Set the first map style as default
            if let firstLayer = mapLayers.first {
                self.mapStyleLayer = firstLayer
            } else {
                // Handle the case where no map layers are returned from the server
                Logger().error("No available map layers from the server.")
            }
        }
    }

    func resolve(_ item: ResolvedItem) async {
        let itemIfAvailable = self.displayableItems
            .first { $0.id == item.id }
        if itemIfAvailable == nil {
            self.displayableItems.append(.resolvedItem(item))
        }
        self.selectedItem = item
        guard let detailedItem = try? await hudhudResolver.lookup(id: item.id, baseURL: DebugStore().baseURL),
              // we make sure that this item is still selected
              detailedItem.id == self.selectedItem?.id,
              let index = self.displayableItems.firstIndex(where: { $0.id == detailedItem.id }) else { return }
        var detailedItemUpdate = detailedItem
        detailedItemUpdate.systemColor = item.systemColor
        detailedItemUpdate.symbol = item.symbol
        self.displayableItems[index] = .resolvedItem(detailedItemUpdate)
        self.selectedItem = detailedItemUpdate
    }

    // Unified route calculation function
    func calculateRoute(
        from location: CLLocation,
        to destination: CLLocationCoordinate2D?,
        additionalWaypoints: [Waypoint] = []
    ) async throws -> RoutingService.RouteCalculationResult {
        let startWaypoint = Waypoint(location: location)

        var waypoints = [startWaypoint]
        if let destinationCoordinate = destination {
            let destinationWaypoint = Waypoint(coordinate: destinationCoordinate)
            waypoints.append(destinationWaypoint)
        }
        waypoints.append(contentsOf: additionalWaypoints)

        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.shapeFormat = .polyline6
        options.distanceMeasurementSystem = .metric
        options.attributeOptions = []

        // Calculate the routes
        let result = try await RoutingService.shared.calculate(host: DebugStore().routingHost, options: options)

        // Return the routes from the result
        return result
    }

    // MARK: - Lifecycle

    init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, motionViewModel: MotionViewModel, userLocationStore: UserLocationStore) {
        self.camera = camera
        self.searchShown = searchShown
        self.motionViewModel = motionViewModel
        self.userLocationStore = userLocationStore
        bindLayersVisability()
        bindCameraToUserLocation()
    }

    // MARK: - Internal

    func trackingAction() async {
        switch self.trackingState {
        case .none:
            await self.focusOnUser()
            self.trackingState = .locateOnce
            Logger.mapInteraction.log("None action required")
        case .locateOnce:
            self.trackingState = .keepTracking
            Logger.mapInteraction.log("locate me Once")
        case .keepTracking:
            self.trackingState = .none
            Logger.mapInteraction.log("keep Tracking of user location")
        }
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
                let routes = try await self.calculateRoute(from: location, to: nil, additionalWaypoints: [currentRoute])
                if let route = routes.routes.first {
                    await self.reroute(with: route)
                }
            } catch {
                Logger.routing.error("Updating routes failed: \(error.localizedDescription)")
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

    func isSFSymbolLayerPresent() -> Bool {
        return self.mapStyle?.layers.contains(where: { $0.identifier == MapLayerIdentifier.restaurants || $0.identifier == MapLayerIdentifier.shops }) ?? false
    }

    func zoomToStreetViewLocation() {
        guard let lat = streetViewScene?.lat else { return }
        guard let lon = streetViewScene?.lon else { return }
        self.camera = .center(CLLocationCoordinate2D(latitude: lat, longitude: lon),
                              zoom: 15, pitch: 0, pitchRange: .fixed(0))
    }

    func loadNearestStreetView(minLon: Double, minLat: Double,
                               maxLon: Double, maxLat: Double) async {
        do {
            self.nearestStreetViewScene = try await self.hudhudStreetView.getStreetViewSceneBBox(box: [minLon, minLat, maxLon, maxLat])
        } catch {
            self.nearestStreetViewScene = nil
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

    func loadStreetViewScene(id: Int) async {
        if let item = self.cachedScenes[id] {
            self.streetViewScene = item
            return
        }

        do {
            if let streetViewScene = try await hudhudStreetView.getStreetViewScene(id: id, baseURL: DebugStore().baseURL) {
                Logger.streetView.log("SVD: streetViewScene0: \(self.streetViewScene.debugDescription)")
                self.streetViewScene = streetViewScene
                self.cachedScenes[streetViewScene.id] = streetViewScene
            }
        } catch {
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

    func preloadStreetViewScene(id: Int) async {
        if self.cachedScenes[id] != nil {
            return
        }

        do {
            if let streetViewScene = try await hudhudStreetView.getStreetViewScene(id: id, baseURL: DebugStore().baseURL) {
                self.cachedScenes[streetViewScene.id] = streetViewScene
            }
        } catch {
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .preview)
}

// MARK: - Private

private extension MapStore {

    func bindLayersVisability() {
        self.$displayableItems
            .map(\.isEmpty)
            .removeDuplicates()
            .sink { [weak self] isEmpty in
                if isEmpty {
                    self?.mapStyle?.layers.forEach { layer in
                        if layer.identifier == MapLayerIdentifier.restaurants || layer.identifier == MapLayerIdentifier.shops {
                            layer.isVisible = true
                        }
                    }
                } else {
                    self?.mapStyle?.layers.forEach { layer in
                        if layer.identifier == MapLayerIdentifier.restaurants || layer.identifier == MapLayerIdentifier.shops {
                            layer.isVisible = false
                        }
                    }
                }
            }
            .store(in: &self.subscriptions)
    }

    func bindCameraToUserLocation() {
        self.userLocationStore.$currentUserLocation
            .compactMap(\.?.coordinate)
            .sink { [weak self] newUserLocation in
                self?.updateCamera(state: .userLocation(newUserLocation))
            }
            .store(in: &self.subscriptions)
    }

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
            self.camera = MapViewCamera.center(userLocation, zoom: 14)
        case .mapItems:
            self.handleMapItems()
        default:
            self.camera = MapViewCamera.center(.riyadh, zoom: 16)
        }
    }

    func updateDetent() {
        do {
            let elements = try path.elements()
            Logger.navigationPath.log("path now: \(elements)")
            self.updateSelectedSheetDetent(to: elements.last)
        } catch {
            Logger.navigationPath.error("update detent error: \(error)")
        }
    }

    func handleMapItems() {
        switch self.mapItems.count {
        case 0:
            break // no items, do nothing
        case 1:
            // if there is only one item ...center around this location
            if let item = mapItems.first, routes == nil {
                self.camera = .center(item.coordinate, zoom: 16)
            }
        case 2...:
            let coordinates = self.mapItems.map(\.coordinate)
            if let camera = CameraState.boundingBox(from: coordinates) {
                self.camera = camera
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
