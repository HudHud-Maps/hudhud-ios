//
//  RouteGeometrySpatialIndex.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

// MARK: - RouteGeometrySpatialIndex

// swiftlint:disable large_tuple
final class RouteGeometrySpatialIndex {

    // MARK: Properties

    private var coordinateInfos: [CoordinateInfo] = []
    private var root: RTreeNode
    private let searchRadius: Measurement<UnitLength> = .meters(50)
    private let nearbyThreshold: Measurement<UnitLength> = .meters(10) // for U-shape detection
    private var lastReportedPosition: ExactRoutePosition?
    private let positionFindingMode: PositionFindingMode

    // MARK: Lifecycle

    init(coordinates: [CLLocationCoordinate2D], positionFindingMode: PositionFindingMode = .accurate) {
        self.root = RTreeNode(bounds: .infinite)
        self.positionFindingMode = positionFindingMode
        self.reindex(using: coordinates)
    }

    // MARK: Functions

    func reindex(using coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        let boundingBox = coordinates.reduce(into: RTreeNode.BoundingBox(minLat: Double.infinity,
                                                                         minLon: Double.infinity,
                                                                         maxLat: -Double.infinity,
                                                                         maxLon: -Double.infinity)) { box, coordinate in
            box.minLat = min(box.minLat, coordinate.latitude)
            box.minLon = min(box.minLon, coordinate.longitude)
            box.maxLat = max(box.maxLat, coordinate.latitude)
            box.maxLon = max(box.maxLon, coordinate.longitude)
        }

        self.root = RTreeNode(bounds: boundingBox)

        self.coordinateInfos.reserveCapacity(coordinates.count)

        var routeDistance: Double = 0
        let gridSize = self.nearbyThreshold.meters
        var spatialGrid: [String: Set<Int>] = [:]

        for (currentIndex, currentCoordinate) in coordinates.enumerated() {
            let gridX = Int(currentCoordinate.longitude / gridSize)
            let gridY = Int(currentCoordinate.latitude / gridSize)

            var proximityIndices = Set<Int>()
            for dx in -1 ... 1 {
                for dy in -1 ... 1 {
                    let key = "\(gridX + dx)|\(gridY + dy)"
                    if let cellIndices = spatialGrid[key] {
                        for neighborIndex in cellIndices {
                            let neighborCoordinate = coordinates[neighborIndex]
                            let distanceToNeighbor = currentCoordinate.distance(to: neighborCoordinate)
                            if distanceToNeighbor < self.nearbyThreshold.meters {
                                proximityIndices.insert(neighborIndex)
                            }
                        }
                    }
                }
            }

            let currentKey = "\(gridX)|\(gridY)"
            spatialGrid[currentKey, default: []].insert(currentIndex)

            if currentIndex > 0 {
                routeDistance += currentCoordinate.distance(to: coordinates[currentIndex - 1])
            }

            self.coordinateInfos.append(CoordinateInfo(index: currentIndex,
                                                       coordinate: currentCoordinate,
                                                       cumulativeDistance: routeDistance,
                                                       nearbyIndices: proximityIndices))

            insert(coordinate: currentCoordinate, index: currentIndex, into: self.root)
        }
    }

    func flush() {
        self.coordinateInfos.removeAll()
        self.root.children?.removeAll()
        self.root.points?.removeAll()
        self.root = RTreeNode(bounds: .infinite)
    }

    func findExactPosition(for point: CLLocationCoordinate2D) -> ExactRoutePosition {
        let candidateIndices = findNearestPointIndices(to: point, radius: searchRadius.meters)
        let bestMatch: (index: Int, distance: Double, projection: ProjectionResult)?

        if let lastPosition = lastReportedPosition {
            let startIdx = max(0, lastPosition.coordinateIndex - 1)
            let endIdx = min(coordinateInfos.count - 1, lastPosition.coordinateIndex + 2)
            let nearLastMatch = findBestMatch(point: point,
                                              searchIndices: Array(startIdx ... endIdx))

            if let match = nearLastMatch, match.distance <= searchRadius.meters {
                bestMatch = match
            } else {
                bestMatch = findBestMatch(point: point,
                                          searchIndices: Array(candidateIndices))
            }
        } else {
            bestMatch = findBestMatch(point: point,
                                      searchIndices: Array(candidateIndices))
        }

        if let match = bestMatch {
            let position = createExactPosition(fromMatch: match,
                                               forPoint: point)
            self.lastReportedPosition = position
            return position
        }

        return fallbackPosition(for: point)
    }

    func interpolate(start: CLLocationCoordinate2D,
                     end: CLLocationCoordinate2D,
                     t: Double) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * t
        let lon = start.longitude + (end.longitude - start.longitude) * t
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

private extension RouteGeometrySpatialIndex {

    struct CoordinateInfo {
        let index: Int
        let coordinate: CLLocationCoordinate2D
        let cumulativeDistance: Double
        let nearbyIndices: Set<Int>
    }

    struct ProjectionResult {
        let coordinate: CLLocationCoordinate2D
        let distanceAlongSegment: Double
        let percentage: Double
    }

    func findBestMatch(point: CLLocationCoordinate2D,
                       searchIndices: [Int]) -> (index: Int, distance: Double, projection: ProjectionResult)? {
        var bestMatch: (index: Int, distance: Double, projection: ProjectionResult)?

        for idx in searchIndices {
            guard idx < self.coordinateInfos.count - 1 else { continue }

            let info = self.coordinateInfos[idx]
            let indicesToCheck = info.nearbyIndices.union([idx])

            for checkIdx in indicesToCheck {
                guard checkIdx < self.coordinateInfos.count - 1 else { continue }

                let start = self.coordinateInfos[checkIdx].coordinate
                let end = self.coordinateInfos[checkIdx + 1].coordinate
                let (distance, projection) = if self.positionFindingMode == .relaxed {
                    self.calculateRelaxedProjection(point: point,
                                                    segmentStart: start,
                                                    segmentEnd: end)
                } else {
                    self.calculateExactProjection(point: point,
                                                  segmentStart: start,
                                                  segmentEnd: end)
                }

                if let currentBest = bestMatch {
                    if distance < currentBest.distance {
                        bestMatch = (checkIdx, distance, projection)
                    }
                } else {
                    bestMatch = (checkIdx, distance, projection)
                }
            }
        }

        return bestMatch
    }

    func createExactPosition(fromMatch match: (index: Int, distance: Double, projection: ProjectionResult),
                             forPoint _: CLLocationCoordinate2D) -> ExactRoutePosition {
        let start = self.coordinateInfos[match.index]

        return ExactRoutePosition(coordinateIndex: match.index,
                                  nextCoordinateIndex: match.index + 1,
                                  segmentIndex: match.index,
                                  exactCoordinate: match.projection.coordinate,
                                  distanceFromStart: start.cumulativeDistance + match.projection.distanceAlongSegment,
                                  distanceFromSegmentStart: match.projection.distanceAlongSegment,
                                  percentageAlongSegment: match.projection.percentage)
    }

    func fallbackPosition(for point: CLLocationCoordinate2D) -> ExactRoutePosition {
        var bestIndex = 0
        var minDistance = Double.infinity

        for (i, info) in self.coordinateInfos.enumerated() {
            let distance = point.distance(to: info.coordinate)
            if distance < minDistance {
                minDistance = distance
                bestIndex = i
            }
        }

        let info = self.coordinateInfos[bestIndex]
        return ExactRoutePosition(coordinateIndex: bestIndex,
                                  nextCoordinateIndex: min(bestIndex + 1, self.coordinateInfos.count - 1),
                                  segmentIndex: bestIndex,
                                  exactCoordinate: info.coordinate,
                                  distanceFromStart: info.cumulativeDistance,
                                  distanceFromSegmentStart: 0,
                                  percentageAlongSegment: 0)
    }

    func calculateExactProjection(point: CLLocationCoordinate2D,
                                  segmentStart: CLLocationCoordinate2D,
                                  segmentEnd: CLLocationCoordinate2D) -> (distance: Double, projection: ProjectionResult) {
        let lat = point.latitude * .pi / 180.0
        let lon = point.longitude * .pi / 180.0
        let lat1 = segmentStart.latitude * .pi / 180.0
        let lon1 = segmentStart.longitude * .pi / 180.0
        let lat2 = segmentEnd.latitude * .pi / 180.0
        let lon2 = segmentEnd.longitude * .pi / 180.0

        let x = cos(lat) * cos(lon)
        let y = cos(lat) * sin(lon)
        let z = sin(lat)

        let x1 = cos(lat1) * cos(lon1)
        let y1 = cos(lat1) * sin(lon1)
        let z1 = sin(lat1)

        let x2 = cos(lat2) * cos(lon2)
        let y2 = cos(lat2) * sin(lon2)
        let z2 = sin(lat2)

        let dot = (x - x1) * (x2 - x1) + (y - y1) * (y2 - y1) + (z - z1) * (z2 - z1)
        let lenSq = pow(x2 - x1, 2) + pow(y2 - y1, 2) + pow(z2 - z1, 2)
        let t = max(0.0, min(1.0, dot / lenSq))

        let px = x1 + t * (x2 - x1)
        let py = y1 + t * (y2 - y1)
        let pz = z1 + t * (z2 - z1)

        let projLat = atan2(pz, sqrt(px * px + py * py)) * 180.0 / .pi
        let projLon = atan2(py, px) * 180.0 / .pi

        let projCoord = CLLocationCoordinate2D(latitude: projLat, longitude: projLon)
        let distanceAlongSegment = segmentStart.distance(to: projCoord)

        return (point.distance(to: projCoord),
                ProjectionResult(coordinate: projCoord,
                                 distanceAlongSegment: distanceAlongSegment,
                                 percentage: t))
    }

    func calculateRelaxedProjection(point: CLLocationCoordinate2D,
                                    segmentStart start: CLLocationCoordinate2D,
                                    segmentEnd end: CLLocationCoordinate2D) -> (distance: Double, projection: ProjectionResult) {
        let startToEnd = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))

        let bearing = start.bearing(to: end)
        let pointBearing = start.bearing(to: point)
        let pointDistance = start.distance(to: point)

        let ex = startToEnd * cos(bearing * .pi / 180.0)
        let ey = startToEnd * sin(bearing * .pi / 180.0)
        let px = pointDistance * cos(pointBearing * .pi / 180.0)
        let py = pointDistance * sin(pointBearing * .pi / 180.0)

        let dot = px * ex + py * ey
        let t = max(0, min(1, dot / (startToEnd * startToEnd)))

        let projectedPoint = self.interpolate(start: start, end: end, t: t)

        let distance = point.distance(to: projectedPoint)
        let projectedDistance = start.distance(to: projectedPoint)

        return (distance,
                ProjectionResult(coordinate: projectedPoint,
                                 distanceAlongSegment: projectedDistance,
                                 percentage: t))
    }

    func insert(coordinate: CLLocationCoordinate2D,
                index: Int,
                into node: RTreeNode) {
        if node.children == nil, node.points == nil {
            node.points = [RTreeNode.RoutePoint(index: index, coordinate: coordinate)]
            return
        }

        if let points = node.points {
            if points.count < node.maxEntries {
                node.points?.append(RTreeNode.RoutePoint(index: index, coordinate: coordinate))
            } else {
                node.children = []
                node.points = nil

                for point in points {
                    let newNode = self.createNodeForPoint(point.coordinate)
                    newNode.points = [RTreeNode.RoutePoint(index: point.index, coordinate: point.coordinate)]
                    node.children?.append(newNode)
                }

                let newNode = self.createNodeForPoint(coordinate)
                newNode.points = [RTreeNode.RoutePoint(index: index, coordinate: coordinate)]
                node.children?.append(newNode)
            }
        } else {
            guard let bestChild = findBestChild(for: coordinate, in: node) else {
                return
            }
            self.insert(coordinate: coordinate, index: index, into: bestChild)
        }
    }

    func findNearestPointIndices(to point: CLLocationCoordinate2D,
                                 radius: Double) -> Set<Int> {
        var indices = Set<Int>()
        self.searchNearestPoints(point: point, radius: radius, node: self.root, indices: &indices)
        return indices
    }

    func searchNearestPoints(point: CLLocationCoordinate2D,
                             radius: Double,
                             node: RTreeNode,
                             indices: inout Set<Int>) {
        if !self.isWithinSearchRadius(point: point, bounds: node.bounds, radius: radius) {
            return
        }

        if let points = node.points {
            for localPoint in points where localPoint.coordinate.distance(to: point) <= radius {
                indices.insert(localPoint.index)
            }
        } else if let children = node.children {
            for child in children {
                self.searchNearestPoints(point: point,
                                         radius: radius,
                                         node: child,
                                         indices: &indices)
            }
        }
    }

    func createNodeForPoint(_ coord: CLLocationCoordinate2D) -> RTreeNode {
        let padding = 0.0001 // padding for the bounding box,
        let bounds = RTreeNode.BoundingBox(minLat: coord.latitude - padding,
                                           minLon: coord.longitude - padding,
                                           maxLat: coord.latitude + padding,
                                           maxLon: coord.longitude + padding)
        return RTreeNode(bounds: bounds)
    }

    func findBestChild(for coordinate: CLLocationCoordinate2D,
                       in node: RTreeNode) -> RTreeNode? {
        guard let children = node.children else {
            assertionFailure("Node must have children")
            return nil
        }

        var bestChild = children[0]
        var minEnlargement = Double.infinity

        for child in children {
            let enlargement = self.calculateEnlargement(of: child.bounds, for: coordinate)
            if enlargement < minEnlargement {
                minEnlargement = enlargement
                bestChild = child
            }
        }

        return bestChild
    }

    func isWithinSearchRadius(point: CLLocationCoordinate2D,
                              bounds: RTreeNode.BoundingBox,
                              radius: Double) -> Bool {
        let latRadius = radius / 111_000
        let lonRadius = radius / (111_000 * cos(point.latitude * .pi / 180))

        let searchBox = RTreeNode.BoundingBox(minLat: point.latitude - latRadius,
                                              minLon: point.longitude - lonRadius,
                                              maxLat: point.latitude + latRadius,
                                              maxLon: point.longitude + lonRadius)

        return bounds.intersects(searchBox)
    }

    func calculateEnlargement(of bounds: RTreeNode.BoundingBox,
                              for coordinate: CLLocationCoordinate2D) -> Double {
        let newMinLat = min(bounds.minLat, coordinate.latitude)
        let newMinLon = min(bounds.minLon, coordinate.longitude)
        let newMaxLat = max(bounds.maxLat, coordinate.latitude)
        let newMaxLon = max(bounds.maxLon, coordinate.longitude)

        let originalArea = (bounds.maxLat - bounds.minLat) *
            (bounds.maxLon - bounds.minLon)
        let newArea = (newMaxLat - newMinLat) * (newMaxLon - newMinLon)

        return newArea - originalArea
    }
}

// MARK: - Distance Finding

extension RouteGeometrySpatialIndex {

    func calculateDistanceAlongRoute(from userLocation: CLLocationCoordinate2D,
                                     to featureLocation: CLLocationCoordinate2D) -> CLLocationDistance {
        let userPosition = self.findExactPosition(for: userLocation)
        let featurePosition = self.findExactPosition(for: featureLocation)

        if userPosition.isAfter(featurePosition) {
            return -(userPosition.distanceFromStart - featurePosition.distanceFromStart)
        }

        return featurePosition.distanceFromStart - userPosition.distanceFromStart
    }

    func isMovingTowardsFeature(userLocation: CLLocationCoordinate2D,
                                featureLocation: CLLocationCoordinate2D,
                                userCourse _: CLLocationDirection) -> Bool {
        let featurePosition = self.findExactPosition(for: featureLocation)
        let userPosition = self.findExactPosition(for: userLocation)

        if userPosition.coordinateIndex == featurePosition.coordinateIndex {
            return userPosition.distanceFromSegmentStart < featurePosition.distanceFromSegmentStart
        }

        return userPosition.coordinateIndex < featurePosition.coordinateIndex
    }
}

// swiftlint:enable large_tuple
