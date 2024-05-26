//
//  DetailFavoriteForm.swift
//  HudHud
//
//  Created by Alaa . on 26/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SFSafeSymbols
import SwiftUI

// MARK: - DetailFavoriteForm

struct DetailFavoriteForm: View { // Add
    @State var types = ["Home", "School", "Work", "Restuarant"]
    @State var newType = ""
    @Binding var item: ResolvedItem
    @Binding var newFavorite: FavoriteCategoriesData
    @Environment(\.dismiss) var dismiss
    @AppStorage("favorites") var favorites = FavoriteItems(items: FavoriteCategoriesData.favoritesInit)

    var body: some View {
        VStack {
            HStack {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .chevronLeft)
                        .foregroundStyle(.black)
                }
                Spacer()
                Text("Details")
                Spacer()
                Button {
                    // if type used delete it then add this
                    if let existingIndex = favorites.favoriteCategoriesData.firstIndex(where: { $0.type == newFavorite.type }) {
                        self.favorites.favoriteCategoriesData.remove(at: existingIndex)
                    }

                    let newFavoriteData = FavoriteCategoriesData(
                        id: .random(in: 1 ... 100),
                        title: !self.newFavorite.type.isEmpty && self.newFavorite.title == self.item.title ? self.newFavorite.type : self.newFavorite.title, // handle this better
                        sfSymbol: self.getSymbol(for: self.newFavorite.type),
                        tintColor: .gray,
                        item: self.item,
                        description: self.newFavorite.description,
                        type: self.newFavorite.type
                    )
                    self.storeFavorite(newFavorite: newFavoriteData)
                    self.dismiss()
                } label: {
                    Text("Add")
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal)

            Form {
                Section {
                    TextField("Name \(!self.newFavorite.type.isEmpty ? self.newFavorite.type : self.item.title)", text: self.$newFavorite.title)
                    HStack {
                        Text("\(self.item.subtitle)")

                        Button {} label: {
                            Image(systemSymbol: .pencil)
                        }
                    }
                }

                TextField("description", text: self.$newFavorite.description.toUnwrapped(defaultValue: ""))

                Picker("Type", selection: self.$newFavorite.type) {
                    ForEach(self.types, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }.pickerStyle(.inline)
                Section {
                    TextField("Add Type", text: self.$newType)
                    Button(action: {
                        //						addNewOption()
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color.blue)
                    }
                }
            }
        }
    }

    // MARK: - Internal

    func storeFavorite(newFavorite: FavoriteCategoriesData) {
        var currentItems = self.favorites.favoriteCategoriesData

        if currentItems.contains(where: { $0.item == newFavorite.item }) {
            return
        }
        currentItems.append(newFavorite)
        self.favorites = FavoriteItems(items: currentItems)
    }

    func getSymbol(for type: String) -> SFSymbol {
        switch type {
        case "Home":
            return .houseFill
        case "Work":
            return .bagFill
        case "School":
            return .buildingColumnsFill
        default:
            return .pin
        }
    }

    // MARK: - Private

    private func addNewOption() {
        guard !self.newType.isEmpty else { return }
        if !self.types.contains(self.newType) {
            self.types.append(self.newType)
            self.newType = ""
        }
    }
}

#Preview {
    @State var item: ResolvedItem = .artwork
    @State var favorite: FavoriteCategoriesData = .favoriteForPreview
    return DetailFavoriteForm(item: $item, newFavorite: $favorite)
}

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
