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
    @State private var typeSymbols: [String: SFSymbol] = [FavoritesItem.Types.home: .houseFill, FavoritesItem.Types.work: .bagFill, FavoritesItem.Types.school: .buildingFill]

    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    @ScaledMetric var imageSize = 30

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
                    MapView<MLNMapViewController>(styleURL: self.styleURL, camera: self.$camera)
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
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .frame(width: self.imageSize, height: self.imageSize)
                                .padding(10)
                                .background(Circle().fill(Color.blue))
                            Text(type)
                            Spacer()
                            if self.selectedType == type {
                                Image(systemSymbol: .checkmark)
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
                        Button {
                            self.addNewOption()
                        } label: {
                            Image(systemSymbol: .plusCircle)
                                .foregroundStyle(Color(UIColor.label))
                        }
                    }
                }
            }
            .formStyle(.automatic)
            .navigationBarTitle("Edit", displayMode: .inline)
            .navigationBarItems(trailing: Button("Add") {
                self.saveChanges()
                self.dismiss()
            })
        }
        .onAppear {
            self.camera = MapViewCamera.center(self.item.coordinate, zoom: 14)
        }
    }

    private func saveChanges() {
        let newFavoritesItem = FavoritesItem(
            id: favoritesItem?.id ?? UUID(),
            title: self.title,
            tintColor: self.favoritesItem?.tintColor ?? Color.gray,
            item: self.item,
            description: self.description.isEmpty ? nil : self.description,
            type: self.selectedType
        )

        // A set of types that should only have their "item" updated
        let updatableTypes: Set<String> = ["Home", "School", "Work"]

        // Check if the item being updated already exists in the list
        if let existingIndex = favorites.favoritesItems.firstIndex(where: { $0.item == newFavoritesItem.item }) {
            // Check if the type has changed and is one of the updatable types
            let existingItem = self.favorites.favoritesItems[existingIndex]

            if existingItem.type != newFavoritesItem.type, updatableTypes.contains(existingItem.type) {
                // Move data to the new type slot
                if let targetIndex = favorites.favoritesItems.firstIndex(where: { $0.type == newFavoritesItem.type }) {
                    self.favorites.favoritesItems[targetIndex].title = existingItem.title
                    self.favorites.favoritesItems[targetIndex].item = existingItem.item
                    self.favorites.favoritesItems[targetIndex].description = existingItem.description

                    // Clear the existing item
                    self.favorites.favoritesItems[existingIndex].title = ""
                    self.favorites.favoritesItems[existingIndex].item = nil
                    self.favorites.favoritesItems[existingIndex].description = nil
                }
            } else {
                // Just update the existing item with new details
                self.favorites.favoritesItems[existingIndex].title = newFavoritesItem.title
                self.favorites.favoritesItems[existingIndex].item = newFavoritesItem.item
                self.favorites.favoritesItems[existingIndex].description = newFavoritesItem.description
            }
        } else if updatableTypes.contains(newFavoritesItem.type) {
            // Handle the case where we're adding a new item of an updatable type
            if let existingTypeIndex = favorites.favoritesItems.firstIndex(where: { $0.type == newFavoritesItem.type }) {
                // Update the existing type item
                self.favorites.favoritesItems[existingTypeIndex].title = newFavoritesItem.title
                self.favorites.favoritesItems[existingTypeIndex].item = newFavoritesItem.item
                self.favorites.favoritesItems[existingTypeIndex].description = newFavoritesItem.description
            } else {
                // If no item of the same type exists, add the new item
                self.favorites.favoritesItems.append(newFavoritesItem)
            }
        } else {
            // Add the new item to the list if it’s not one of the updatable types
            self.favorites.favoritesItems.append(newFavoritesItem)
        }
    }

    // MARK: - Lifecycle

    init(item: ResolvedItem, favoritesItem: FavoritesItem? = nil) {
        self.item = item
        self.favoritesItem = favoritesItem
        _title = State(initialValue: favoritesItem?.title ?? item.title)
        _description = State(initialValue: favoritesItem?.description ?? "")
        _selectedType = State(initialValue: favoritesItem?.type ?? "")
        _types = State(initialValue: ["Home", "School", "Work", "Restaurant", "Other"])
    }

    // MARK: - Private

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
        EditFavoritesFormView(item: resolvedItem, favoritesItem: favorite)
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
                EditFavoritesFormView(item: resolvedItem, favoritesItem: favorite)
            }
    }
}
