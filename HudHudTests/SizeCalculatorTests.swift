//
//  SizeCalculatorTests.swift
//  HudHudTests
//
//  Created by Patrick Kladek on 22.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreFoundation
@testable import HudHud
import Testing
import UIKit

struct SizeCalculatorTests {

    // Only for Simulator, real device has higher limits
    @Test(.enabled(if: UIApplication.isSimulator), arguments: [
        CGSize(width: 13504, height: 6752),
        CGSize(width: 27008, height: 13504)
    ])
    func textClipping(size _: CGSize) throws {
        let clipped = DeviceSupport.clipToMaximumSupportedTextureSize(CGSize(width: 13504, height: 6752))
        #expect(clipped.width == 6752)
        #expect(clipped.height == 3376)
    }
}
