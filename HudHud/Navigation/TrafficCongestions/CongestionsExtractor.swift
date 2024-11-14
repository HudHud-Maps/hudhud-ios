//
//  CongestionsExtractor.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI

// MARK: - RouteTrafficManager

private enum RouteTrafficManager {

    // MARK: Static Properties

    private static var annotationsCache: [Int: [ValhallaOsrmAnnotation]] = [:]
    private static var lastExactPosition: [Int: ExactRoutePosition] = [:]

    // MARK: Static Functions

    static func setRoute(_ route: Route) {
        guard self.annotationsCache[route.id] == nil else { return }

        var annotations: [ValhallaOsrmAnnotation] {
            let decoder = JSONDecoder()
            return route.steps
                .compactMap(\.annotations)
                .flatMap { annotations in
                    annotations.compactMap { annotationString in
                        guard let data = annotationString.data(using: .utf8) else {
                            return nil
                        }
                        return try? decoder.decode(ValhallaOsrmAnnotation.self, from: data)
                    }
                }
        }

        self.annotationsCache[route.id] = annotations
    }

    // swiftlint:disable:next cyclomatic_complexity
    static func extractCongestionSegments(from route: Route, considering currentPosition: ExactRoutePosition) -> [CongestionSegment] {
        guard let annotations = annotationsCache[route.hashValue] else {
            return []
        }

        self.lastExactPosition[route.id] = currentPosition

        var segments = [CongestionSegment]()
        var currentPoints: [CLLocationCoordinate2D] = []
        var segmentStartIndex = currentPosition.coordinateIndex
        var lastCongestion: String?

        let startPoint = route.geometry[currentPosition.coordinateIndex].clLocationCoordinate2D
        let endPoint = route.geometry[currentPosition.coordinateIndex + 1].clLocationCoordinate2D

        // calculate a point a bit behind the exact position to make it look like below the chevron
        let behindProgress = max(0.0, currentPosition.percentageAlongSegment - 0.025)
        let behindPoint = CLLocationCoordinate2D(
            latitude: startPoint.latitude + (endPoint.latitude - startPoint.latitude) * behindProgress,
            longitude: startPoint.longitude + (endPoint.longitude - startPoint.longitude) * behindProgress
        )

        currentPoints.append(behindPoint)
        currentPoints.append(currentPosition.exactCoordinate)

        var currentCoordinateIndex = currentPosition.coordinateIndex
        while currentCoordinateIndex < min(annotations.count, route.geometry.count) {
            guard let congestion = annotations[currentCoordinateIndex].congestion else {
                currentCoordinateIndex += 1
                continue
            }

            if lastCongestion == nil {
                lastCongestion = congestion
            }

            if congestion == lastCongestion {
                if currentCoordinateIndex == currentPosition.coordinateIndex {
                    // only add next point if we're not at the end
                    if currentPosition.percentageAlongSegment < 1.0 {
                        currentPoints.append(endPoint)
                    }
                } else {
                    currentPoints.append(route.geometry[currentCoordinateIndex].clLocationCoordinate2D)
                    if currentCoordinateIndex + 1 < route.geometry.count {
                        currentPoints.append(route.geometry[currentCoordinateIndex + 1].clLocationCoordinate2D)
                    }
                }
            } else {
                if let level = lastCongestion {
                    segments.append(CongestionSegment(
                        level: level,
                        startIndex: segmentStartIndex,
                        endIndex: currentCoordinateIndex,
                        points: currentPoints
                    ))
                }

                segmentStartIndex = currentCoordinateIndex
                lastCongestion = congestion
                currentPoints = [route.geometry[currentCoordinateIndex].clLocationCoordinate2D]
                if currentCoordinateIndex + currentCoordinateIndex < route.geometry.count {
                    currentPoints.append(route.geometry[currentCoordinateIndex + 1].clLocationCoordinate2D)
                }
            }

            currentCoordinateIndex += 1
        }

        if let level = lastCongestion, !currentPoints.isEmpty {
            segments.append(CongestionSegment(
                level: level,
                startIndex: segmentStartIndex,
                endIndex: min(annotations.count, route.geometry.count),
                points: currentPoints
            ))
        }

        return segments
    }

    static func cleanup() {
        self.annotationsCache.removeAll(keepingCapacity: true)
        self.lastExactPosition.removeAll()
    }
}

extension Route {
    func extractCongestionSegments(considering userPosition: ExactRoutePosition) -> [CongestionSegment] {
        RouteTrafficManager.setRoute(self)

        return RouteTrafficManager.extractCongestionSegments(from: self, considering: userPosition)
    }
}
