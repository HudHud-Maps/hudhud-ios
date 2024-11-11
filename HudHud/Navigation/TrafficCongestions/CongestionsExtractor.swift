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

// MARK: - CongestionSegment

extension Route {

    var annotations: [ValhallaOsrmAnnotation] {
        let decoder = JSONDecoder()

        return steps
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

    func extractCongestionSegments() -> [CongestionSegment] {
        var mergedSegments: [CongestionSegment] = []
        var currentSegment: CongestionSegment?
        var currentIndex = 0

        for annotation in self.annotations {
            guard let congestion = annotation.congestion else {
                continue
            }

            let startIndex = currentIndex
            let endIndex = startIndex + 1

            if endIndex >= geometry.count {
                break
            }

            let segmentGeometry = Array(geometry[startIndex ... endIndex])

            if let current = currentSegment,
               current.level == congestion,
               let lastSegment = current.geometry.last {
                currentSegment = CongestionSegment(level: congestion, geometry: current.geometry + [lastSegment])
            } else {
                if let current = currentSegment {
                    mergedSegments.append(current)
                }
                currentSegment = CongestionSegment(level: congestion, geometry: segmentGeometry.map(\.clLocationCoordinate2D))
            }

            currentIndex = endIndex
        }

        if let lastSegment = currentSegment {
            mergedSegments.append(lastSegment)
        }
        return mergedSegments
    }
}

// MARK: - Private

private extension Route {

    func findEndIndex(startingFrom startIndex: Int, distance: Double) -> Int {
        var remainingDistance = distance
        var currentIndex = startIndex

        while currentIndex < geometry.count - 1, remainingDistance > 0 {
            let segmentDistance = geometry[currentIndex]
                .clLocationCoordinate2D
                .distance(to: geometry[currentIndex + 1].clLocationCoordinate2D)
            if remainingDistance >= segmentDistance {
                remainingDistance -= segmentDistance
                currentIndex += 1
            } else {
                break
            }
        }

        return currentIndex
    }
}
