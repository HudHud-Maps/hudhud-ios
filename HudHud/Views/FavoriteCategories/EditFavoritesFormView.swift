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

        // Find the index of the item with the same type
        if let existingIndex = favorites.favoritesItems.firstIndex(where: { $0.type == newFavoritesItem.type }) {
            // Move data from one type to another within the updatable types
            if let sourceIndex = favorites.favoritesItems.firstIndex(where: { $0.item != nil && $0.type != newFavoritesItem.type && updatableTypes.contains($0.type) }) {
                var sourceItem = self.favorites.favoritesItems[sourceIndex]
                var targetItem = self.favorites.favoritesItems[existingIndex]

                // Transfer the data
                targetItem.title = sourceItem.title
                targetItem.item = sourceItem.item
                targetItem.description = sourceItem.description

                // Clear the source item
                sourceItem.title = ""
                sourceItem.item = nil
                sourceItem.description = nil

                // Update the array
                self.favorites.favoritesItems[sourceIndex] = sourceItem
                self.favorites.favoritesItems[existingIndex] = targetItem
            } else {
                // If no existing item to transfer data from, just update the existing item
                self.favorites.favoritesItems[existingIndex].title = newFavoritesItem.title
                self.favorites.favoritesItems[existingIndex].item = newFavoritesItem.item
                self.favorites.favoritesItems[existingIndex].description = newFavoritesItem.description
            }
        } else {
            // Add a new item if it's not a static type
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
