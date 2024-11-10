//
//  SearchMapOverlay.swift
//  HudHud
//
//  Created by Naif Alrashed on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - SearchMapOverlay

struct SearchMapOverlay: View {

    // MARK: Properties

    @ObservedObject var searchViewStore: SearchViewStore
    let streetViewStore: StreetViewStore
    let sheetStore: SheetStore
    @ObservedObject var trendingStore: TrendingStore
    let mapStore: MapStore
    let userLocationStore: UserLocationStore

    // MARK: Content

    var body: some View {
        VStack {
            Spacer()
            if self.searchViewStore.routingStore.ferrostarCore.isNavigating == false, self.streetViewStore.streetViewScene == nil {
                HStack(alignment: .bottom) {
                    HStack(alignment: .bottom) {
                        MapButtonsView(
                            mapButtonsData: [
                                MapButtonData(sfSymbol: .icon(.map)) {
                                    self.sheetStore.show(.mapStyle)
                                },
                                MapButtonData(sfSymbol: MapButtonData.buttonIcon(for: self.searchViewStore.mode)) {
                                    switch self.searchViewStore.mode {
                                    case let .live(provider):
                                        self.searchViewStore.mode = .live(provider: provider.next())
                                        Logger.searchView.info("Map Mode live")
                                    case .preview:
                                        self.searchViewStore.mode = .live(provider: .hudhud)
                                        Logger.searchView.info("Map Mode toursprung")
                                    }
                                },
                                MapButtonData(sfSymbol: self.mapStore.getCameraPitch() > 0 ? .icon(.diamond) : .icon(.cube)) {
                                    if self.mapStore.getCameraPitch() > 0 {
                                        self.mapStore.camera.setPitch(0)
                                    } else {
                                        self.mapStore.camera.setZoom(17)
                                        self.mapStore.camera.setPitch(60)
                                    }
                                },
                                MapButtonData(sfSymbol: .icon(.terminal)) {
                                    self.sheetStore.show(.debugView)
                                }
                            ]
                        )

                        if (self.mapStore.mapViewPort?.zoom ?? 0) > 10,
                           let item = self.streetViewStore.nearestStreetViewScene {
                            Button {
                                self.streetViewStore.streetViewScene = item
                                self.streetViewStore.zoomToStreetViewLocation()
                            } label: {
                                Image(systemSymbol: .binoculars)
                                    .font(.title2)
                                    .padding(10)
                                    .foregroundColor(.gray)
                                    .background(Color.white)
                                    .cornerRadius(15)
                                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                                    .fixedSize()
                            }
                        }
                    }

                    Spacer()
                    VStack(alignment: .trailing) {
                        CurrentLocationButton(mapStore: self.mapStore)
                    }
                }
                .padding(.horizontal)
                .offset(y: -(self.sheetStore.sheetHeight + 8))
                .animation(.easeInOut(duration: 0.2), value: self.sheetStore.sheetHeight)
            }
        }
        .safeAreaInset(edge: .top) {
            if self.searchViewStore.routingStore.ferrostarCore.isNavigating == false, self.streetViewStore.streetViewScene == nil {
                CategoriesBannerView(
                    catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData,
                    searchStore: self.searchViewStore
                )
            }
        }
        .overlay(alignment: .top) {
            self.streetView
        }
        .onChange(of: self.sheetStore.selectedDetent) {
            if self.sheetStore.selectedDetent == .small {
                Task {
                    await self.reloadPOITrending()
                }
            }
        }
        .onChange(of: self.mapStore.mapViewPort) {
            // we should not be storing a reference to the mapView in the map store...
            guard let viewport = self.mapStore.mapViewPort else { return }

            let boundingBox = viewport.calculateBoundingBox(viewWidth: 400, viewHeight: 800)
            let minLongitude = boundingBox.southEast.longitude
            let minLatitude = boundingBox.southEast.latitude
            let maxLongitude = boundingBox.northWest.longitude
            let maxLatitude = boundingBox.northWest.latitude

            Task {
                await self.streetViewStore.loadNearestStreetView(minLon: minLongitude, minLat: minLatitude, maxLon: maxLongitude, maxLat: maxLatitude)
            }
        }
        .task {
            await self.reloadPOITrending()
        }
    }
}

private extension SearchMapOverlay {

    var streetView: some View {
        VStack {
            if self.streetViewStore.streetViewScene != nil {
                StreetView(store: self.streetViewStore)
            }
        }
        .onChange(of: self.streetViewStore.streetViewScene) { _, _ in
            self.updateSheetShown()
        }
        .onChange(of: self.streetViewStore.fullScreenStreetView) { _, _ in
            self.updateSheetShown()
        }
    }

    func updateSheetShown() {
        self.sheetStore.isShown.value = !self.streetViewStore.fullScreenStreetView && self.streetViewStore.streetViewScene.isNil
    }

    func reloadPOITrending() async {
        do {
            let currentUserLocation = await self.userLocationStore.location(allowCached: true)?.coordinate
            let trendingPOI = try await trendingStore.getTrendingPOIs(page: 1, limit: 100, coordinates: currentUserLocation, baseURL: DebugStore().baseURL)
            self.trendingStore.trendingPOIs = trendingPOI
        } catch {
            self.trendingStore.trendingPOIs = nil
            Logger.searchView.error("\(error.localizedDescription)")
        }
    }
}

private extension MapViewPort {

    func calculateBoundingBox(viewWidth: CGFloat, viewHeight: CGFloat) -> (northWest: CLLocationCoordinate2D, southEast: CLLocationCoordinate2D) {
        // Earth's circumference in meters
        let earthCircumference: Double = 40_075_016.686

        // Meters per pixel at given zoom level
        let metersPerPixel = earthCircumference / pow(2.0, self.zoom + 8)

        // Calculate the span in meters
        let spanX = Double(viewWidth) * metersPerPixel
        let spanY = Double(viewHeight) * metersPerPixel

        // Convert the latitude to radians
        let latInRad = self.center.latitude * .pi / 180.0

        // Calculate the latitude and longitude span
        let latitudeSpan = (spanY / 2) / 111_320.0
        let longitudeSpan = (spanX / 2) / (111_320.0 * cos(latInRad))

        // North-west (top-left) coordinate
        let northWest = CLLocationCoordinate2D(latitude: self.center.latitude + latitudeSpan,
                                               longitude: self.center.longitude - longitudeSpan)

        // South-east (bottom-right) coordinate
        let southEast = CLLocationCoordinate2D(latitude: self.center.latitude - latitudeSpan,
                                               longitude: self.center.longitude + longitudeSpan)

        return (northWest, southEast)
    }
}

#Preview {
    SearchMapOverlay(searchViewStore: .storeSetUpForPreviewing, streetViewStore: .storeSetUpForPreviewing, sheetStore: .storeSetUpForPreviewing, trendingStore: TrendingStore(), mapStore: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
}
