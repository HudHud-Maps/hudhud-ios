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

    // MARK: Properties

    let item: ResolvedItem
    let favoritesItem: FavoritesItem?
    @ObservedObject var favoritesStore = FavoritesStore()

    @State var newType: String = ""
    @State var types: [String]
    @ScaledMetric var imageSize = 30
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedType: String
    @State private var typeSymbols: [String: SFSymbol] = [FavoritesItem.Types.home: .houseFill, FavoritesItem.Types.work: .bagFill, FavoritesItem.Types.school: .buildingFill]
    private let sheetStore: SheetStore
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    // MARK: Lifecycle

    init(item: ResolvedItem, favoritesItem: FavoritesItem? = nil, favoritesStore: FavoritesStore, sheetStore: SheetStore) {
        self.item = item
        self.favoritesItem = favoritesItem
        _title = State(initialValue: favoritesItem?.title ?? item.title)
        _description = State(initialValue: favoritesItem?.description ?? "")
        _selectedType = State(initialValue: favoritesItem?.type ?? "Other")
        _types = State(initialValue: ["Home", "School", "Work", "Restaurant", "Other"])
        self.favoritesStore = favoritesStore
        self.sheetStore = sheetStore
    }

    // MARK: Content

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Name", text: self.$title)
                        HStack {
                            Text("\(self.item.subtitle ?? self.item.coordinate.formatted())")
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
                .navigationBarItems(
                    leading: Button {
                        self.sheetStore.popSheet()
                    } label: {
                        Label("Back", systemSymbol: .arrowBackward)
                    },
                    trailing: Button("Add") {
                        self.saveChanges()
                        self.sheetStore.popToRoot()
                    }
                )
            }
            .onAppear {
                self.camera = MapViewCamera.center(self.item.coordinate, zoom: 14)
            }
        }
    }

}

// MARK: - Private

private extension EditFavoritesFormView {

    func saveChanges() {
        self.favoritesStore.saveChanges(
            title: self.title,
            tintColor: self.favoritesItem?.tintColor ?? .entertainmentLeisure,
            item: self.item,
            description: self.description,
            selectedType: self.selectedType
        )
    }

    func addNewOption() {
        guard !self.newType.isEmpty, !self.types.contains(self.newType) else { return }
        self.types.append(self.newType)
        self.newType = ""
    }
}

#Preview {
    @Previewable @State var resolvedItem: ResolvedItem = .artwork
    @Previewable @State var favorite: FavoritesItem = .favoriteForPreview
    @Previewable @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    @Previewable @StateObject var favoritesStore = FavoritesStore()
    return NavigationStack {
        EditFavoritesFormView(item: resolvedItem, favoritesItem: favorite, favoritesStore: favoritesStore, sheetStore: .storeSetUpForPreviewing)
    }
}

#Preview("EditForvoritesFormView") {
    @Previewable @State var resolvedItem: ResolvedItem = .ketchup
    @Previewable @State var favorite: FavoritesItem = .favoriteForPreview
    @Previewable @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    @Previewable @State var isLinkActive = true
    @Previewable @StateObject var favoritesStore = FavoritesStore()
    return NavigationStack {
        Text("root view")
            .navigationDestination(isPresented: $isLinkActive) {
                EditFavoritesFormView(item: resolvedItem, favoritesItem: favorite, favoritesStore: favoritesStore, sheetStore: .storeSetUpForPreviewing)
            }
    }
}
