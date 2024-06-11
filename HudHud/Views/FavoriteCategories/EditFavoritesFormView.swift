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
    let favoritesItem: FavoritesItem?
    @Environment(\.dismiss) var dismiss

    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoritesItem.favoritesInit)

    @State private var title: String = ""
    @State private var description: String = ""
    @State var newType: String = ""
    @State private var selectedType: String
    @State var types: [String]
    @State private var typeSymbols: [String: SFSymbol] = ["Home": .houseFill, "Work": .bagFill, "School": .buildingFill]

    @State var freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
    @Binding var camera: MapViewCamera
    private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: self.$title)
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
                    TextEditor(text: self.$description)
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
                                .background(Circle().fill(Color.blue))
                            Text(type)
                            Spacer()
                            if self.selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.selectedType = type
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
                self.saveChanges()
                print(self.favorites, "after ==========")
                self.dismiss()
            })
        }
    }

    // MARK: - Lifecycle

    init(item: ResolvedItem, favoritesItem: FavoritesItem?, camera: Binding<MapViewCamera>) {
        self.item = item
        self.favoritesItem = favoritesItem
        _title = State(initialValue: favoritesItem?.title ?? "")
        _description = State(initialValue: favoritesItem?.description ?? "")
        _selectedType = State(initialValue: favoritesItem?.type ?? "")
        _types = State(initialValue: ["Home", "School", "Work", "Restaurant"])
        _camera = camera
    }

    // MARK: - Private

    private func saveChanges() {
        let newFavoritesItem = FavoritesItem(
            id: favoritesItem?.id ?? Int.random(in: 1000 ... 9999),
            title: self.title,
            sfSymbol: self.favoritesItem?.sfSymbol ?? SFSymbol.houseFill,
            tintColor: self.favoritesItem?.tintColor ?? Color.gray,
            item: self.item,
            description: self.description.isEmpty ? nil : self.description,
            type: self.selectedType
        )

        // a set of types that should only be updated
        let updatableTypes: Set<String> = ["Home", "School", "Work"]

        if updatableTypes.contains(newFavoritesItem.type),
           let existingIndex = favorites.favoritesItems.firstIndex(where: { $0.type == newFavoritesItem.type || $0.id == newFavoritesItem.id }) {
            // Update the existing item at the found index
            var existingItem = self.favorites.favoritesItems[existingIndex]
            existingItem.title = newFavoritesItem.title
            existingItem.item = newFavoritesItem.item
            existingItem.description = newFavoritesItem.description
            existingItem.type = newFavoritesItem.type

            self.favorites.favoritesItems[existingIndex] = existingItem
        } else {
            self.favorites.favoritesItems.append(newFavoritesItem)
        }
    }

    private func addNewOption() {
        guard !self.newType.isEmpty, !self.types.contains(self.newType) else { return }
        self.types.append(self.newType)
        self.newType = ""
    }

}

#Preview {
    @State var resolvedItem: ResolvedItem = .artwork
    @State var favorite: FavoritesItem = .favoriteForPreview
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    return NavigationStack {
        EditFavoritesFormView(item: resolvedItem, favoritesItem: favorite, camera: $camera)
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
                EditFavoritesFormView(item: resolvedItem, favoritesItem: favorite, camera: $camera)
            }
    }
}
