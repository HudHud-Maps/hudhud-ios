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

    // MARK: Properties

    @Published var favoritesItems: [FavoritesItem] = []

    @AppStorage("favorites") private var storedFavorites: String = ""

    // MARK: Lifecycle

    init() {
        self.loadFavorites()
    }

    // MARK: Functions

    func loadFavorites() {
        if let favorites = FavoritesResolvedItems(rawValue: storedFavorites) {
            self.favoritesItems = favorites.favoritesItems
        } else {
            self.favoritesItems = FavoritesItem.favoritesInit
        }
    }

    func saveFavorites() {
        let favorites = FavoritesResolvedItems(items: favoritesItems)
        self.storedFavorites = favorites.rawValue
    }

    func saveChanges(title: String, tintColor: FavoritesItem.TintColor, item: ResolvedItem, description: String, selectedType: String) {
        let newFavoritesItem = self.createFavoritesItem(title: title, tintColor: tintColor, item: item, description: description, type: selectedType)

        if let existingIndex = favoritesItems.firstIndex(where: { $0.item == newFavoritesItem.item }) {
            self.updateExistingItem(at: existingIndex, with: newFavoritesItem)
        } else {
            self.handleNewItem(of: newFavoritesItem)
        }
        self.saveFavorites()
    }

    func deleteFavorite(_ favorite: FavoritesItem) {
        if let index = favoritesItems.firstIndex(where: { $0 == favorite }) {
            if self.isUpdatableType(favorite.type) {
                self.clearItem(at: index)
            } else {
                self.favoritesItems.remove(at: index)
            }
            self.saveFavorites()
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

    // MARK: - Private

    private func createFavoritesItem(title: String, tintColor: FavoritesItem.TintColor, item: ResolvedItem?, description: String?, type: String) -> FavoritesItem {
        return FavoritesItem(
            id: UUID(),
            title: title,
            tintColor: tintColor,
            item: item,
            description: description,
            type: type
        )
    }

    private func updateExistingItem(at index: Int, with newItem: FavoritesItem) {
        if self.favoritesItems[index].type != newItem.type, self.isUpdatableType(self.favoritesItems[index].type) {
            self.moveData(from: index, toType: newItem.type)
        } else {
            self.updateItem(at: index, with: newItem)
        }
    }

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
