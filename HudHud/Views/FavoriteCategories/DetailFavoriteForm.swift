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
    @State private var typeSymbols: [String: SFSymbol] = ["Home": .houseFill, "Work": .bagFill, "School": .buildingFill]

    var body: some View {
        VStack {
            HStack {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .chevronLeft)
                        .foregroundStyle(Color(UIColor.label))
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
                        title: !self.newFavorite.type.isEmpty && self.newFavorite.title == self.item.title ? self.newFavorite.type : self.newFavorite.title,
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
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            .padding(.horizontal)
            Spacer()
            Form {
                Section {
                    FloatingLabelTextField(text: self.$newFavorite.title, placeholder: "Name: \(!self.newFavorite.type.isEmpty ? self.newFavorite.type : self.item.title)")
                    HStack {
                        Text("\(self.item.subtitle)")
                        Spacer()
                        Button {} label: {
                            Image(systemSymbol: .pencil)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Section(header: Text("description").foregroundStyle(.gray)) {
                        TextEditor(text: self.$newFavorite.description.toUnwrapped(defaultValue: ""))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }
                .padding(.vertical)
                Section(header: Text("Select Type")) {
                    ForEach(self.types, id: \.self) { type in
                        HStack {
                            Image(systemSymbol: self.typeSymbols[type] ?? .heartFill)
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(10)
                                .background {
                                    Circle().fill(Color.blue)
                                }
                            Text(type)
                            Spacer()
                            if self.newFavorite.type == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.newFavorite.type = type
                        }
                        .padding(.vertical, 5)
                    }
                }
                Section {
                    HStack {
                        FloatingLabelTextField(text: self.$newType, placeholder: "Add Type")
                        Button(action: {
                            self.addNewOption()
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color(UIColor.label))
                        }
                    }
                }
            }
            .formStyle(.columns)
            .padding(.horizontal)
            Spacer()
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
