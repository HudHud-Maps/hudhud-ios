//
//  MapViewStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 06/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import MapLibre
import OSLog
import SFSafeSymbols

// MARK: - SelectedPointOfInterest

enum SelectedPointOfInterest {
    // selected item from the search results
    case searchSuggestion(id: String)
    // selected item from the map itself
    case mapElement(ResolvedItem)
}

// MARK: - MapViewStore

@MainActor
class MapViewStore {

    private let mapStore: MapStore

    // MARK: - Lifecycle

    init(mapStore: MapStore) {
        self.mapStore = mapStore
    }

    // MARK: - Internal

    func didTapOnMap(containing features: [any MLNFeature]) {
        if self.mapStore.displayableItems.count == 1 {
            self.mapStore.displayableItems = []
        }
        guard let item = extractItemTapped(from: features) else {
            // user tapped nothing - deselect
            Logger.mapInteraction.debug("Tapped nothing - setting to nil...")
            self.mapStore.selectedItem = nil
            return
        }
        switch item {
        case let .searchSuggestion(placeID):
            let poi = self.mapStore.mapItems.first { poi in
                poi.id == placeID
            }

            if let poi {
                Logger.mapInteraction.debug("setting poi")
                self.mapStore.selectedItem = poi
            } else {
                Logger.mapInteraction.warning("User tapped a feature but it's not a ResolvedItem")
            }
        case let .mapElement(resolvedItem):
            let itemIfAvailable = self.mapStore.displayableItems
                .first { $0.id == resolvedItem.id }
            if itemIfAvailable == nil {
                self.mapStore.displayableItems.append(AnyDisplayableAsRow(resolvedItem))
            }
            self.mapStore.selectedItem = resolvedItem
        }
    }

    func extractItemTapped(from features: [any MLNFeature]) -> SelectedPointOfInterest? {
        for feature in features {
            if let poi = feature.attribute(forKey: "poi_id") as? String {
                return .searchSuggestion(id: poi)
            } else if let item = extractItem(from: feature) {
                return .mapElement(item)
            }
        }
        return nil
    }

    // MARK: - Private

    private func extractItem(from feature: any MLNFeature) -> ResolvedItem? {
        guard let feature = feature as? MLNPointFeature,
              let id = feature.attribute(forKey: "id") as? Int,
              let name = (feature.attribute(forKey: "name_ar") ?? feature.attribute(forKey: "name_en")) as? String,
              let description = (feature.attribute(forKey: "description_ar") ?? feature.attribute(forKey: "description_en")) as? String else {
            return nil
        }
        return ResolvedItem(
            id: String(id),
            title: name,
            subtitle: description,
            category: feature.attribute(forKey: "category_en") as? String,
            symbol: self.symbol(from: feature) ?? .pin,
            type: .hudhud,
            coordinate: feature.coordinate,
            phone: feature.attribute(forKey: "phone_number") as? String,
            website: self.website(from: feature),
            rating: feature.attribute(forKey: "rating") as? Double,
            ratingCount: feature.attribute(forKey: "ratings_count") as? Int
        )
    }

    private func website(from feature: MLNPointFeature) -> URL? {
        if let stringURL = feature.attribute(forKey: "website") as? String {
            URL(string: stringURL)
        } else {
            nil
        }
    }

    private func symbol(from feature: MLNPointFeature) -> SFSymbol? {
        if let symbolString = feature.attribute(forKey: "ios_category_icon_name") as? String {
            // we cannot create sf symbol in a type safe way here as we are parsing the symbol name from an outside source (the map)
            SFSymbol(rawValue: symbolString) // swiftlint:disable:this sf_symbol_init
        } else {
            nil
        }
    }
}
