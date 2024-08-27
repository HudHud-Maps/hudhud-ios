//
//  MotionViewModel.swift
//  HudHud
//
//  Created by Patrick Kladek on 05.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

// MARK: - MotionViewModel

final class MotionViewModel: ObservableObject {

    // MARK: Nested Types

    // MARK: - Internal

    struct Position: Equatable {

        // MARK: Static Properties

        static var initial = MotionViewModel.Position(heading: 0, pitch: 90)

        // MARK: Properties

        var heading: Double
        var pitch: Double

        // MARK: Lifecycle

        init(heading: Double, pitch: Double) {
            self.heading = heading
            self.pitch = Double.minimum(pitch, 180)
        }

        // MARK: Static Functions

        // MARK: - Internal

        static func + (left: Position, right: Position) -> Position {
            let pitch = (left.pitch + right.pitch).limit(upper: 180)

            return Position(heading: left.heading + right.heading,
                            pitch: pitch)
        }

        static func * (left: Position, right: Double) -> Position {
            return Position(heading: left.heading * right,
                            pitch: left.pitch * right)
        }
    }

    enum Size: CaseIterable {
        case compact
        case fullscreen
    }

    // MARK: Static Properties

    static let shared = MotionViewModel()

    // MARK: Properties

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var position: Position = .initial
    @Published var size: Size = .compact
    @Published var pageLoaded = false

    private var positionOffet: Position?

    // MARK: Lifecycle

    private init(coordinate: CLLocationCoordinate2D? = nil, position: Position = .initial, positionOffet: Position? = nil, size: Size = .compact) {
        self.coordinate = coordinate
        self.position = position
        self.positionOffet = positionOffet
        self.size = size
    }

    // MARK: Functions

    func adding(translation: CGSize) {
        if let dragStartOffset = self.positionOffet {
            // try to mimic scrolling so your finger stays below the initial tap point
            // needs fine tuning once we have the StreetView WebView
            let scaleFactor = 0.25

            let newHeading = (dragStartOffset.heading + (translation.width * scaleFactor)).wrap(min: 0, max: 360)
            let newPitch = (dragStartOffset.pitch + (translation.height * scaleFactor)).limit(upper: 180)

            self.position.heading = newHeading
            self.position.pitch = newPitch
        } else {
            self.positionOffet = self.position
        }
    }

    func endTranslation() {
        self.positionOffet = nil
    }
}

// MARK: - Previewable

extension MotionViewModel: Previewable {

    static var storeSetUpForPreviewing: MotionViewModel = .shared
}
