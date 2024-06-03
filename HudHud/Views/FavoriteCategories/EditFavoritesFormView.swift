//
//  EditFavoritesFormView.swift
//  HudHud
//
//  Created by Alaa . on 29/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SFSafeSymbols
import SwiftUI

// MARK: - EditFavoritesFormView

struct EditFavoritesFormView: View {
    @Binding var item: ResolvedItem
    @Binding var newFavorite: FavoriteCategoriesData
    @State var types = ["Home", "School", "Work", "Restuarant"]
    @State var newType = ""
    @Environment(\.dismiss) var dismiss
    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoriteCategoriesData.favoritesInit)
    @State private var typeSymbols: [String: SFSymbol] = ["Home": .houseFill, "Work": .bagFill, "School": .buildingFill]

    private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
    @State var freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
    @Binding var camera: MapViewCamera

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
                    // add

                    self.dismiss()
                } label: {
                    Text("Edit")
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            .padding()
            Form {
                Section {
                    TextField("Name \(!self.newFavorite.type.isEmpty ? self.newFavorite.type : self.item.title)", text: self.$newFavorite.title)
                    HStack {
                        Text("\(self.$item.subtitle)")
                        Spacer()
                        Button {} label: {
                            Image(systemSymbol: .pencil)
                                .foregroundStyle(.gray)
                        }.disabled(true)
                    }
                }
                Section {
                    MapView(styleURL: self.styleURL, camera: self.$camera)
                        .frame(height: 140)
                        .disabled(true)
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
                        TextField("Add Type", text: self.$newType)
                        Button(action: {
                            self.addNewOption()
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color(UIColor.label))
                        }
                    }
                }
            }
            .formStyle(.automatic)
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
        self.favorites = FavoritesResolvedItems(items: currentItems)
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
    @State var resolvedItem: ResolvedItem = .artwork
    @State var favorite: FavoriteCategoriesData = .favoriteForPreview
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    return EditFavoritesFormView(item: $resolvedItem, newFavorite: $favorite, camera: $camera)
}

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
