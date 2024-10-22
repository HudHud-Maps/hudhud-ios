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
    @Test(.enabled(if: UIApplication.isSimulator), .enabled(if: DeviceSupport.model == .iPhone16Pro), arguments: [
        CGSize(width: 6752, height: 3376),
        CGSize(width: 13504, height: 6752),
        CGSize(width: 27008, height: 13504)
    ])
    func imageClippingiPhone16Pro(size: CGSize) throws {
        let clipped = size.clipToMaximumSupportedTextureSize()
        #expect(clipped.width == 6752)
        #expect(clipped.height == 3376)
    }

    // Only for Simulator, real device has higher limits
    @Test(.enabled(if: UIApplication.isSimulator), .enabled(if: DeviceSupport.model == .iPhone15Pro), arguments: [
        CGSize(width: 3376, height: 1688),
        CGSize(width: 6752, height: 3376),
        CGSize(width: 13504, height: 6752),
        CGSize(width: 27008, height: 13504)
    ])
    func imageClippingiPhone15Pro(size: CGSize) throws {
        let clipped = size.clipToMaximumSupportedTextureSize()
        #expect(clipped.width == 3376)
        #expect(clipped.height == 1688)
    }
}
