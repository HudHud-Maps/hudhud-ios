//
//  FavoritesStore.swift
//  HudHud
//
//  Created by Alaa . on 21/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import Foundation
import SwiftUI

class FavoritesStore: ObservableObject {
    @AppStorage("favorites") private var storedFavorites: String = ""

    @Published var favoritesItems: [FavoritesItem] = []

    func loadFavorites() {
        if let favorites = FavoritesResolvedItems(rawValue: storedFavorites) {
            self.favoritesItems = favorites.favoritesItems
        } else {
            // Fallback to initial favorites if decoding fails
            self.favoritesItems = FavoritesItem.favoritesInit
        }
    }

    func saveFavorites() {
        let favorites = FavoritesResolvedItems(items: favoritesItems)
        self.storedFavorites = favorites.rawValue
    }

    func saveChanges(title: String, tintColor: FavoritesItem.TintColor, item: ResolvedItem, description: String, selectedType: String) {
        let newFavoritesItem = FavoritesItem(
            id: UUID(),
            title: title,
            tintColor: tintColor,
            item: item,
            description: description.isEmpty ? nil : description,
            type: selectedType
        )

        if let existingIndex = favoritesItems.firstIndex(where: { $0.item == newFavoritesItem.item }) {
            self.updateExistingItem(at: existingIndex, with: newFavoritesItem)
        } else {
            self.handleNewItem(of: newFavoritesItem)
        }
        self.saveFavorites()
    }

    private func updateExistingItem(at index: Int, with newItem: FavoritesItem) {
        let existingItem = self.favoritesItems[index]
        if existingItem.type != newItem.type, self.isUpdatableType(existingItem.type) {
            self.moveData(from: index, toType: newItem.type)
        } else {
            self.updateItem(at: index, with: newItem)
        }
    }

    private func handleNewItem(of newItem: FavoritesItem) {
        if let existingTypeIndex = favoritesItems.firstIndex(where: { $0.type == newItem.type }), isUpdatableType(newItem.type) {
            self.updateItem(at: existingTypeIndex, with: newItem)
        } else {
            self.favoritesItems.append(newItem)
        }
    }

    private func moveData(from index: Int, toType newType: String) {
        if let targetIndex = favoritesItems.firstIndex(where: { $0.type == newType }) {
            self.updateItem(at: targetIndex, with: self.favoritesItems[index])
            self.clearItem(at: index)
        }
    }

    func deleteFavorite(_ favorite: FavoritesItem) {
        let updatableTypes: Set<String> = ["Home", "School", "Work"]
        if let index = favoritesItems.firstIndex(where: { $0 == favorite }) {
            if updatableTypes.contains(favorite.type) {
                self.favoritesItems[index].title = ""
                self.favoritesItems[index].item = nil
                self.favoritesItems[index].description = nil
            } else {
                self.favoritesItems.remove(at: index)
            }
            self.saveFavorites()
        }
    }

    // MARK: - Lifecycle

    init() {
        self.loadFavorites()
    }

    // MARK: - Private

    private func updateItem(at index: Int, with newItem: FavoritesItem) {
        self.favoritesItems[index].title = newItem.title
        self.favoritesItems[index].item = newItem.item
        self.favoritesItems[index].description = newItem.description
    }

    private func clearItem(at index: Int) {
        self.favoritesItems[index].title = ""
        self.favoritesItems[index].item = nil
        self.favoritesItems[index].description = nil
    }

    private func isUpdatableType(_ type: String) -> Bool {
        return ["Home", "School", "Work"].contains(type)
    }
}
