//
//  SizeCalculatorTests.swift
//  HudHudTests
//
//  Created by Patrick Kladek on 22.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreFoundation
import Testing
import UIKit
@testable import HudHud

struct SizeCalculatorTests {

    // Only for Simulator, real device has higher limits
    @Test(.enabled(if: UIApplication.isSimulator), .enabled(if: DeviceSupport.model == .iPhone16Pro), arguments: [
        ImageSize(width: 6752, height: 3376),
        ImageSize(width: 13504, height: 6752),
        ImageSize(width: 27008, height: 13504)
    ])
    func imageClippingiPhone16Pro(size: ImageSize) throws {
        let clipped = size.clipToMaximumSupportedTextureSize()
        #expect(clipped.width == 6752)
        #expect(clipped.height == 3376)
    }
}
