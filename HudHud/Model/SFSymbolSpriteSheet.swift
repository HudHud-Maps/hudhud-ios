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

    static var circle: UIImage = Self.generateCircle().withRenderingMode(.alwaysTemplate)

    // MARK: - Private

    private static func generateCircle() -> UIImage {
        let size = CGSize(width: 38, height: 38)

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

        for icon in icons {
            tempDict[icon] = self.createSymbolImage(symbolName: icon)
        }

        return tempDict
    }

    private static func createSymbolImage(symbolName: String) -> UIImage {
        let symbolImage: UIImage = if let resolvedImage = UIImage(systemName: symbolName) {
            resolvedImage
        } else {
            UIImage(systemName: "mappin")!
        }

        let size = CGSize(width: 38, height: 38)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

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

    private static func createSymbolImageWithCircle(symbolName: String, backgroundColor: UIColor) -> UIImage {
        let symbolImage: UIImage = if let resolvedImage = UIImage(systemName: symbolName) {
            resolvedImage
        } else {
            UIImage(systemName: "mappin")!
        }

        let size = CGSize(width: 38, height: 38)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

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
