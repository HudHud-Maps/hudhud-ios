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
    let item: ResolvedItem
    @Binding var newFavorite: FavoritesItem
    @State var types = ["Home", "School", "Work", "Restaurant"]
    @State var newType = ""
    @Environment(\.dismiss) var dismiss
    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoritesItem.favoritesInit)
    @State private var typeSymbols: [String: SFSymbol] = ["Home": .houseFill, "Work": .bagFill, "School": .buildingFill]

    private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
    @State var freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
    @Binding var camera: MapViewCamera

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name \(!self.newFavorite.type.isEmpty ? self.newFavorite.type : self.item.title)", text: self.$newFavorite.title)
                    HStack {
                        Text("\(self.item.subtitle)")
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
                .padding(-20)
                Section(header: Text("description").foregroundStyle(.gray)) {
                    TextEditor(text: self.$newFavorite.description.toUnwrapped(defaultValue: ""))
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.vertical)
                }

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
            .navigationBarTitle("Edit", displayMode: .inline)
            .navigationBarItems(trailing: Button("Add") {
                print(self.favorites, "before ==========")
                self.updateFavorite(favorite: self.newFavorite)
                print(self.favorites, "after ==========")
                self.dismiss()
            })
        }
    }

    // MARK: - Internal

    func updateFavorite(favorite: FavoritesItem) {
        var currentItems = self.favorites.favoritesItems

        if let existingIndex = currentItems.firstIndex(where: { $0.type == favorite.type }) {
            currentItems[existingIndex].item = favorite.item
            currentItems[existingIndex].title = favorite.title
            currentItems[existingIndex].description = favorite.description
            currentItems[existingIndex].type = favorite.type
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
    @State var favorite: FavoritesItem = .favoriteForPreview
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    return NavigationStack {
        EditFavoritesFormView(item: resolvedItem, newFavorite: $favorite, camera: $camera)
    }
}

#Preview("EditForvoritesFormView") {
    @State var resolvedItem: ResolvedItem = .ketchup
    @State var favorite: FavoritesItem = .favoriteForPreview
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    @State var isLinkActive = true
    return NavigationStack {
        Text("root view")
            .navigationDestination(isPresented: $isLinkActive) {
                EditFavoritesFormView(item: resolvedItem, newFavorite: $favorite, camera: $camera)
            }
    }
}

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
