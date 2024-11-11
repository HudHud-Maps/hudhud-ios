//
//  ImageSize.swift
//  HudHud
//
//  Created by Patrick Kladek on 05.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

// MARK: - ImageSize

struct ImageSize {

    // MARK: Properties

    let width: Int
    let height: Int

    // MARK: Static Functions

    static func square(_ length: Int) -> ImageSize {
        return ImageSize(width: length, height: length)
    }

    // MARK: Functions

    func formatted() -> String {
        return self.width.formatted() + " x " + self.height.formatted()
    }
}

extension UIImage {

    var imageSize: ImageSize {
        return ImageSize(width: Int(self.size.width), height: Int(self.size.height))
    }
}
