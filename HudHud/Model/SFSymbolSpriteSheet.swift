//
//  SFSymbolSpriteSheet.swift
//  HudHud
//
//  Created by patrick on 09.07.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

enum SFSymbolSpriteSheet {

    static var spriteMapping: [String: UIImage] = Self.generate()

    private static let size = CGSize(width: 30, height: 30)
    private static let internalSize = CGSize(width: 24, height: 24)

    static var defaultMapPin: UIImage = {
        let renderer = UIGraphicsImageRenderer(size: size)

        return Self.createSymbolImageWithCircle(symbolImage: UIImage(systemName: "mappin")!, backgroundColor: .systemIndigo, renderer: renderer, size: size, internalSize: internalSize)
    }()

    static let adaptiveColors: [(name: String, color: UIColor)] = [
        ("systemRed", .systemRed),
        ("systemGreen", .systemGreen),
        ("systemBlue", .systemBlue),
        ("systemOrange", .systemOrange),
        ("systemYellow", .systemYellow),
        ("systemPink", .systemPink),
        ("systemPurple", .systemPurple),
        ("systemTeal", .systemTeal),
        ("systemIndigo", .systemIndigo)
    ]

    // MARK: - Private

    private static func generateCircle() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // Draw black circle
            let circlePath = UIBezierPath(ovalIn: rect)
            UIColor.black.setFill()
            circlePath.fill()
        }
        return image
    }

    private static func generate() -> [String: UIImage] {
        let startDate = Date()
        let icons = [
            "cart.fill",
            "fork.knife",
            "building.2.fill",
            "building.columns.fill",
            "building.fill",
            "bed.double.fill",
            "cross.fill",
            "cross.case.fill",
            "creditcard.and.123",
            "banknote.fill",
            "tshirt.fill",
            "building.2.crop.circle.fill",
            "books.vertical.fill",
            "cup.and.saucer.fill",
            "dumbbell.fill",
            "film"
        ]

        var tempDict: [String: UIImage] = [:]

        let renderer = UIGraphicsImageRenderer(size: size)
        for icon in icons {
            let symbolImage = self.rawImage(for: icon)
            for color in self.adaptiveColors {
                let name = "\(icon)\(color.name)"
                tempDict[name] = self.createSymbolImageWithCircle(symbolImage: symbolImage, backgroundColor: color.color, renderer: renderer, size: self.size, internalSize: self.internalSize)
            }
        }

        return tempDict
    }

    private static func rawImage(for symbolName: String) -> UIImage {
        let symbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1)
        let symbolImage: UIImage = if let resolvedImage = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration) {
            resolvedImage
        } else {
            UIImage(systemName: "mappin", withConfiguration: symbolConfiguration)!
        }
        return symbolImage
    }

    private static func createSymbolImageWithCircle(symbolImage: UIImage, backgroundColor: UIColor, renderer: UIGraphicsImageRenderer, size: CGSize, internalSize: CGSize) -> UIImage {
        let image = renderer.image { _ in
            let rect = CGRect(origin: CGPoint(x: 2, y: 2), size: internalSize)

            // Draw black circle
            let circlePath = UIBezierPath(ovalIn: rect)
            backgroundColor.setFill()
            circlePath.fill()

            // Draw white outline
            UIColor.white.setStroke()
            circlePath.lineWidth = 2
            circlePath.stroke()

            // Draw SF Symbol in the center
            let symbolRect = CGRect(
                x: rect.midX - symbolImage.size.width / 2,
                y: rect.midY - symbolImage.size.height / 2,
                width: symbolImage.size.width,
                height: symbolImage.size.height
            )
            symbolImage.withTintColor(.white).draw(in: symbolRect)
        }
        return image
    }
}
