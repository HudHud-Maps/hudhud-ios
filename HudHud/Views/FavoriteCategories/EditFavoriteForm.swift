//
//  EditFavoriteForm.swift
//  HudHud
//
//  Created by Alaa . on 26/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct EditFavoriteForm: View {
    @State var types = ["Home", "School", "Work", "Restuarant"]
    @State var newType = ""
    @Environment(\.dismiss) var dismiss
    @Binding var item: FavoriteCategoriesData
    @AppStorage("favorites") var favorites = FavoriteItems(items: FavoriteCategoriesData.favoritesInit)

    var body: some View {
        VStack {
            HStack {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .chevronLeft)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 15)
                }
                Spacer()
                Text("Edit")
                Spacer()
                Button {
                    self.updateFavorite(favorite: self.item)
                    self.dismiss()
                } label: {
                    Text("Edit")
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(.blue)
                        .cornerRadius(8)
                }
                .buttonBorderShape(.roundedRectangle)
            }
            .padding(.horizontal)
            Form {
                Section {
                    TextField("Name", text: self.$item.title)
                    HStack {
                        if let address = item.item?.subtitle {
                            Text("\(address)")
                        }
                        Button {} label: {
                            Image(systemSymbol: .pencil)
                        }
                    }
                }

                TextField("description", text: self.$item.description.toUnwrapped(defaultValue: ""))

                Picker("Type", selection: self.$item.type) {
                    ForEach(self.types, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }.pickerStyle(.inline)
                Section {
                    TextField("Add Type", text: self.$newType)
                    Button(action: {
                        self.addNewOption()
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color.blue)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }

    // MARK: - Internal

    func updateFavorite(favorite: FavoriteCategoriesData) {
        var currentItems = self.favorites.favoriteCategoriesData

        if let existingIndex = currentItems.firstIndex(where: { $0.id == favorite.id }) {
            currentItems[existingIndex] = favorite
        } else {
            currentItems.append(favorite)
        }
        self.favorites = FavoriteItems(items: currentItems)
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
    @State var data: FavoriteCategoriesData = .favoriteForPreview
    return EditFavoriteForm(item: $data)
}
