//
//  SymbolStyleLayer.swift
//  HudHud
//
//  Created by patrick on 11.07.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import InternalUtils
import MapLibreSwiftDSL
import UIKit

public extension SymbolStyleLayer {

    func iconImage(mappings: [AnyHashable: UIImage], default defaultImage: UIImage) -> Self {
        return modified(self) { it in

            let expression1 = NSExpression(forKeyPath: "ios_category_icon_name")
            let expression2 = NSExpression(forKeyPath: "ios_category_icon_color")

            // Create an NSExpression that concatenates the two key paths
            let attributeExpression = expression1.mgl_appending(expression2)
            let mappingExpressions = mappings.mapValues { image in
                NSExpression(forConstantValue: image.sha256())
            }
            let mappingDictionary = NSDictionary(dictionary: mappingExpressions)
            let defaultExpression = NSExpression(forConstantValue: defaultImage.sha256())

            // swiftlint:disable force_cast
            it.iconImageName = NSExpression(forMLNMatchingKey: attributeExpression,
                                            in: mappingDictionary as! [NSExpression: NSExpression],
                                            default: defaultExpression)
            // swiftlint:enable force_cast
            it.iconImages = mappings.values + [defaultImage]
        }
    }

}
