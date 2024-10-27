//
//  MapContentLayers.swift
//  HudHud
//
//  Created by Ali Hilal on 26/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCore
import FerrostarCoreFFI
import FerrostarMapLibreUI
import FerrostarSwiftUI
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI

extension MapViewContainer {
    @MapViewContentBuilder
    func makeAlternativeRouteLayers() -> [StyleLayerDefinition] {
        self.routingStore.alternativeRoutes.enumerated().flatMap { index, route in

            let feature = MLNPolylineFeature(coordinates: route.geometry.clLocationCoordinate2Ds)
            feature.attributes = ["routeId": route.id]
            let polylineSource = ShapeSource(identifier: "alternative-route-\(route.id)") {
                feature
            }

            let routePoints = self.routingStore.routePoints

            let layers: [StyleLayerDefinition] = [
                LineStyleLayer(
                    identifier: MapLayerIdentifier.routeCasing(index),
                    source: polylineSource
                )
                .lineCap(.round)
                .lineJoin(.round)
                .lineColor(.lightGray)
                .lineWidth(interpolatedBy: .zoomLevel,
                           curveType: .linear,
                           parameters: NSExpression(forConstantValue: 1.5),
                           stops: NSExpression(forConstantValue: [18: 10, 20: 20])),

                LineStyleLayer(
                    identifier: MapLayerIdentifier.routeInner(index),
                    source: polylineSource
                )
                .lineCap(.round)
                .lineJoin(.round)
                .lineColor(.systemBlue.withAlphaComponent(0.5))
                .lineWidth(interpolatedBy: .zoomLevel,
                           curveType: .linear,
                           parameters: NSExpression(forConstantValue: 1.5),
                           stops: NSExpression(forConstantValue: [18: 8, 20: 14])),

                CircleStyleLayer(
                    identifier: MapLayerIdentifier.simpleCirclesRoute + "\(route.id)",
                    source: routePoints
                )
                .radius(16)
                .color(.systemRed)
                .strokeWidth(2)
                .strokeColor(.white),

                SymbolStyleLayer(
                    identifier: MapLayerIdentifier.simpleSymbolsRoute + "\(route.id)",
                    source: routePoints
                )
                .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                .iconColor(.white)
            ]

            return layers
        }
    }

    @MapViewContentBuilder
    func makeSelectedRouteLayers(for route: Route) -> [StyleLayerDefinition] {
        let polylineSource = ShapeSource(identifier: "selected-route") {
            MLNPolylineFeature(coordinates: route.geometry.clLocationCoordinate2Ds)
        }

        [
            LineStyleLayer(
                identifier: "selected-route-casing",
                source: polylineSource
            )
            .lineCap(.round)
            .lineJoin(.round)
            .lineColor(.white)
            .lineWidth(interpolatedBy: .zoomLevel,
                       curveType: .linear,
                       parameters: NSExpression(forConstantValue: 1.5),
                       stops: NSExpression(forConstantValue: [18: 14, 20: 26])),

            LineStyleLayer(
                identifier: "selected-route-inner",
                source: polylineSource
            )
            .lineCap(.round)
            .lineJoin(.round)
            .lineColor(.systemBlue)
            .lineWidth(interpolatedBy: .zoomLevel,
                       curveType: .linear,
                       parameters: NSExpression(forConstantValue: 1.5),
                       stops: NSExpression(forConstantValue: [18: 11, 20: 18]))
        ]
    }

    @MapViewContentBuilder
    func makeCongestionLayers(for routes: [Route]) -> [StyleLayerDefinition] {
        let congestionLevels = ["moderate", "heavy", "severe"]
        routes.enumerated().flatMap { index, route in
            let segments = route.extractCongestionSegments()
            return congestionLevels.flatMap { level in
                let source = self.congestionSource(for: level, segments: segments, id: route.id)
                return [self.congestionLayer(for: level, source: source, index: index)]
            }
        }
    }

    @MapViewContentBuilder
    func makeCustomSymbolLayers() -> [StyleLayerDefinition] {
        [
            SymbolStyleLayer(
                identifier: MapLayerIdentifier.customPOI,
                source: MLNSource(identifier: "hpoi"),
                sourceLayerIdentifier: "public.poi"
            )
            .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
            .iconAllowsOverlap(false)
            .text(featurePropertyNamed: "name")
            .textFontSize(11)
            .maximumTextWidth(8.0)
            .textHaloColor(UIColor.white)
            .textHaloWidth(1.0)
            .textHaloBlur(0.5)
            .textAnchor("top")
            .textColor(expression: SFSymbolSpriteSheet.colorExpression)
            .textOffset(CGVector(dx: 0, dy: 1.2))
            .minimumZoomLevel(13.0)
            .maximumZoomLevel(22.0)
            .textFontNames(["IBMPlexSansArabic-Regular"])
        ]
    }

    @MapViewContentBuilder
    func makePointLayers() -> [StyleLayerDefinition] {
        let pointSource = self.mapStore.points

        [
            // Clustered pins
            CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesClustered, source: pointSource)
                .radius(16)
                .color(.systemRed)
                .strokeWidth(2)
                .strokeColor(.white)
                .predicate(NSPredicate(format: "cluster == YES")),

            SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsClustered, source: pointSource)
                .textColor(.white)
                .text(expression: NSExpression(format: "CAST(point_count, 'NSString')"))
                .predicate(NSPredicate(format: "cluster == YES")),

            // Unclustered pins
            SymbolStyleLayer(identifier: MapLayerIdentifier.simpleCircles, source: pointSource.makeMGLSource())
                .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
                .iconAllowsOverlap(false)
                .text(featurePropertyNamed: "name")
                .textFontSize(11)
                .maximumTextWidth(8.0)
                .textHaloColor(UIColor.white)
                .textHaloWidth(1.0)
                .textHaloBlur(0.5)
                .textAnchor("top")
                .textColor(expression: SFSymbolSpriteSheet.colorExpression)
                .textOffset(CGVector(dx: 0, dy: 1.2))
                .minimumZoomLevel(13.0)
                .maximumZoomLevel(22.0)
                .predicate(NSPredicate(format: "cluster != YES")),

            // Selected pin
            CircleStyleLayer(identifier: MapLayerIdentifier.selectedCircle, source: self.mapStore.selectedPoint)
                .radius(24)
                .color(UIColor(self.mapStore.selectedItem.value?.color ?? Color(.systemRed)))
                .strokeWidth(2)
                .strokeColor(.white)
                .predicate(NSPredicate(format: "cluster != YES")),

            SymbolStyleLayer(identifier: MapLayerIdentifier.selectedCircleIcon, source: self.mapStore.selectedPoint)
                .iconImage(UIImage(systemSymbol: self.mapStore.selectedItem.value?.symbol ?? .mappin,
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 24))
                        .withRenderingMode(.alwaysTemplate))
                .iconColor(.white)
                .predicate(NSPredicate(format: "cluster != YES"))
        ]
    }

    @MapViewContentBuilder
    func makeStreetViewLayer() -> [StyleLayerDefinition] {
        [
            SymbolStyleLayer(identifier: "street-view-point", source: self.streetViewStore.streetViewSource)
                .iconImage(UIImage(systemSymbol: .cameraCircleFill,
                                   withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .black]))
                        .resize(.square(32)))
                .iconRotation(featurePropertyNamed: "heading")
        ]
    }

    private func congestionSource(for level: String, segments: [CongestionSegment], id: Int) -> ShapeSource {
        ShapeSource(identifier: "congestion-\(level)-\(id)") {
            segments.filter { $0.level == level }.map { segment in
                MLNPolylineFeature(coordinates: segment.geometry)
            }
        }
    }

    private func congestionLayer(for level: String, source: ShapeSource, index: Int) -> LineStyleLayer {
        LineStyleLayer(identifier: MapLayerIdentifier.congestion(level, index: index), source: source)
            .lineCap(.round)
            .lineJoin(.round)
            .lineColor(self.colorForCongestionLevel(level))
            .lineWidth(
                interpolatedBy: .zoomLevel,
                curveType: .linear,
                parameters: NSExpression(forConstantValue: 1.5),
                stops: NSExpression(forConstantValue: [
                    14: 6,
                    16: 7,
                    18: 9,
                    20: 16
                ])
            )
    }

    private func colorForCongestionLevel(_ level: String) -> UIColor {
        switch level {
        case "unknown": return .gray
        case "low": return .green
        case "moderate": return .yellow
        case "heavy": return .orange
        case "severe": return .red
        default: return .blue
        }
    }
}
