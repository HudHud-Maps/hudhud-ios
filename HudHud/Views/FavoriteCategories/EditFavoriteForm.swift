//
//  EditFavoriteForm.swift
//  HudHud
//
//  Created by Alaa . on 26/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

struct EditFavoriteForm: View {
    @State var types = ["Home", "School", "Work", "Restuarant"]
    @State var newType = ""
    @Environment(\.dismiss) var dismiss
    @Binding var item: FavoriteCategoriesData
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
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            .padding()
            Form {
                Section {
                    FloatingLabelTextField(text: self.$item.title, placeholder: "Name")
                    HStack {
                        if let address = item.item?.subtitle {
                            Text("\(address)")
                        }
                        Spacer()
                        Button {} label: {
                            Image(systemSymbol: .pencil)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Section(header: Text("description").foregroundStyle(.gray)) {
                        TextEditor(text: self.$item.description.toUnwrapped(defaultValue: ""))
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
                            if self.item.type == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.item.type = type
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
