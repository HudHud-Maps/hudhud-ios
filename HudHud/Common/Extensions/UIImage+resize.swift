//
//  UIImage+resize.swift
//  HudHud
//
//  Created by Patrick Kladek on 15.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import UIKit

extension UIImage {

    func resize(_ newSize: CGSize, scale: CGFloat? = nil) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        if let scale {
            format.scale = scale
        }

        let image = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }

        return image.withRenderingMode(renderingMode)
    }
}
