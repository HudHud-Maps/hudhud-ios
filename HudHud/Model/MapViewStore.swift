//
//  MapViewStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 06/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import FerrostarCoreFFI
import MapLibre
import OSLog
import SwiftUI

// MARK: - MapViewStore

@MainActor
final class MapViewStore: ObservableObject {

    // MARK: Properties

    @Published var selectedDetent: PresentationDetent = .small
    @Published var allowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    @Published var path = NavigationPath()

    @State var streetViewHeading: Float = .zero

    private let mapActionHandler: MapActionHandler
    private let routingStore: RoutingStore
    private let mapStore: MapStore

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(mapStore: MapStore, routingStore: RoutingStore) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore)
        self.mapStore = mapStore
        self.routingStore = routingStore
        self.showPotentialRouteWhenAvailable()
        self.updateDetentWhenAppropriate()
        self.showSelectedDetentWhenSelectingAnItem()
    }

    // MARK: Functions

    // MARK: - Internal

    func didTapOnMap(containing features: [any MLNFeature]) {
        let didHaveAnAction = self.mapActionHandler.didTapOnMap(containing: features)
        if !didHaveAnAction {
            // user tapped nothing - deselect
            Logger.mapInteraction.debug("Tapped nothing - setting to nil...")
            if !self.path.isEmpty {
                self.path.removeLast()
            }
            self.mapStore.unselectItem()
        }
    }

    func reset() {
        self.resetAllowedDetents()
        self.selectedDetent = .small
        if !self.path.isEmpty {
            self.path.removeLast()
        }
    }

    func resetAllowedDetents() {
        self.allowedDetents = [.small, .medium, .large]
    }
}

private extension MapViewStore {
    func showPotentialRouteWhenAvailable() {
        self.routingStore.$potentialRoute
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] newPotentialRoute in

                if let newPotentialRoute {
                    guard let self,
                          self.path.contains(SheetSubView.self) == false else { return }
                    self.path.append(SheetSubView.navigationPreview)

                    self.mapStore.updateCamera(state: .route(newPotentialRoute))
                } else {
                    if let lastElement = self?.path.last(), let somethingElse = lastElement as? SheetSubView, somethingElse == .navigationPreview {
                        self?.path.removeLast()
                    }
                }
            }
            .store(in: &self.subscriptions)
    }

    func updateDetentWhenAppropriate() {
        Publishers.CombineLatest3(
            self.routingStore.$navigatingRoute,
            self.$path,
            self.mapStore.$displayableItems
        )
        .sink { [weak self] navigatingRoute, path, items in
            guard let self else { return }
            let elements = try? path.elements()
            let isThereAnyPOIsOnTheMap = if self.mapStore.selectedItem != nil, self.mapStore.displayableItems.count > 1 {
                true
            } else {
                !items.isEmpty
            }
            let isCurrentSheetListOfSearchResults: Bool = if case .resolvedItem = items.first, self.mapStore.displayableItems.count > 1 {
                true
            } else {
                false
            }
            self.updateSelectedSheetDetent(
                isCurrentlyNavigating: navigatingRoute != nil,
                navigationPathItem: elements?.last,
                isThereAnyPOIsOnTheMap: isThereAnyPOIsOnTheMap,
                isCurrentSheetListOfSearchResults: isCurrentSheetListOfSearchResults
            )
        }
        .store(in: &self.subscriptions)
    }

    func showSelectedDetentWhenSelectingAnItem() {
        self.mapStore.$selectedItem
            .compactMap { $0 }
            .sink { [weak self] selectedItem in
                guard let self, self.routingStore.potentialRoute == nil else {
                    return
                }
                if !self.path.isEmpty {
                    self.path.removeLast()
                }
                self.path.append(selectedItem)
            }
            .store(in: &self.subscriptions)
    }

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

    func updateSelectedSheetDetent(isCurrentlyNavigating: Bool, navigationPathItem: Any?, isThereAnyPOIsOnTheMap _: Bool, isCurrentSheetListOfSearchResults: Bool) {
        if isCurrentlyNavigating {
            let closed: PresentationDetent = .height(0)
            self.allowedDetents = [closed]
            self.selectedDetent = closed
            return
        }

        // If routes exist or an item is selected, use the medium detent

        guard let navigationPathItem else {
            self.allowedDetents = [.small, .third, .large]
            if isCurrentSheetListOfSearchResults {
                self.selectedDetent = .large
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
            case .navigationPreview:
                self.allowedDetents = [.height(150), .nearHalf]
                self.selectedDetent = .nearHalf
            }
        }
        if navigationPathItem is ResolvedItem {
            self.allowedDetents = [.small, .third, .nearHalf, .large]
            self.selectedDetent = .nearHalf
        }
    }
}

// MARK: - Previewable

extension MapViewStore: Previewable {
    static let storeSetUpForPreviewing = MapViewStore(
        mapStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing
    )
}
