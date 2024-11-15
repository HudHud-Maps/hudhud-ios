//
//  DeviceSupport.swift
//  HudHud
//
//  Created by Patrick Kladek on 22.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import Metal

// MARK: - DeviceSupport

enum DeviceSupport {

    // MARK: Nested Types

    // swiftlint:disable identifier_name
    // From https://stackoverflow.com/a/46234519/7269707
    enum Model: String {

        // Simulator
        case simulator = "simulator/sandbox"

        // iPod
        case iPod1 = "iPod 1"
        case iPod2 = "iPod 2"
        case iPod3 = "iPod 3"
        case iPod4 = "iPod 4"
        case iPod5 = "iPod 5"
        case iPod6 = "iPod 6"
        case iPod7 = "iPod 7"

        // iPad
        case iPad2 = "iPad 2"
        case iPad3 = "iPad 3"
        case iPad4 = "iPad 4"
        case iPadAir = "iPad Air "
        case iPadAir2 = "iPad Air 2"
        case iPadAir3 = "iPad Air 3"
        case iPadAir4 = "iPad Air 4"
        case iPadAir5 = "iPad Air 5"
        case iPad5 = "iPad 5" // iPad 2017
        case iPad6 = "iPad 6" // iPad 2018
        case iPad7 = "iPad 7" // iPad 2019
        case iPad8 = "iPad 8" // iPad 2020
        case iPad9 = "iPad 9" // iPad 2021
        case iPad10 = "iPad 10" // iPad 2022

        // iPad Mini
        case iPadMini = "iPad Mini"
        case iPadMini2 = "iPad Mini 2"
        case iPadMini3 = "iPad Mini 3"
        case iPadMini4 = "iPad Mini 4"
        case iPadMini5 = "iPad Mini 5"
        case iPadMini6 = "iPad Mini 6"

        // iPad Pro
        case iPadPro9_7 = "iPad Pro 9.7\""
        case iPadPro10_5 = "iPad Pro 10.5\""
        case iPadPro11 = "iPad Pro 11\""
        case iPadPro2_11 = "iPad Pro 11\" 2nd gen"
        case iPadPro3_11 = "iPad Pro 11\" 3rd gen"
        case iPadPro12_9 = "iPad Pro 12.9\""
        case iPadPro2_12_9 = "iPad Pro 2 12.9\""
        case iPadPro3_12_9 = "iPad Pro 3 12.9\""
        case iPadPro4_12_9 = "iPad Pro 4 12.9\""
        case iPadPro5_12_9 = "iPad Pro 5 12.9\""

        // iPhone
        case iPhone4 = "iPhone 4"
        case iPhone4S = "iPhone 4S"
        case iPhone5 = "iPhone 5"
        case iPhone5S = "iPhone 5S"
        case iPhone5C = "iPhone 5C"
        case iPhone6 = "iPhone 6"
        case iPhone6Plus = "iPhone 6 Plus"
        case iPhone6S = "iPhone 6S"
        case iPhone6SPlus = "iPhone 6S Plus"
        case iPhoneSE = "iPhone SE"
        case iPhone7 = "iPhone 7"
        case iPhone7Plus = "iPhone 7 Plus"
        case iPhone8 = "iPhone 8"
        case iPhone8Plus = "iPhone 8 Plus"
        case iPhoneX = "iPhone X"
        case iPhoneXS = "iPhone XS"
        case iPhoneXSMax = "iPhone XS Max"
        case iPhoneXR = "iPhone XR"
        case iPhone11 = "iPhone 11"
        case iPhone11Pro = "iPhone 11 Pro"
        case iPhone11ProMax = "iPhone 11 Pro Max"
        case iPhoneSE2 = "iPhone SE 2nd gen"
        case iPhone12Mini = "iPhone 12 Mini"
        case iPhone12 = "iPhone 12"
        case iPhone12Pro = "iPhone 12 Pro"
        case iPhone12ProMax = "iPhone 12 Pro Max"
        case iPhone13Mini = "iPhone 13 Mini"
        case iPhone13 = "iPhone 13"
        case iPhone13Pro = "iPhone 13 Pro"
        case iPhone13ProMax = "iPhone 13 Pro Max"
        case iPhoneSE3 = "iPhone SE 3nd gen"
        case iPhone14 = "iPhone 14"
        case iPhone14Plus = "iPhone 14 Plus"
        case iPhone14Pro = "iPhone 14 Pro"
        case iPhone14ProMax = "iPhone 14 Pro Max"
        case iPhone15 = "iPhone 15"
        case iPhone15Plus = "iPhone 15 Plus"
        case iPhone15Pro = "iPhone 15 Pro"
        case iPhone15ProMax = "iPhone 15 Pro Max"
        case iPhone16 = "iPhone 16"
        case iPhone16Plus = "iPhone 16 Plus"
        case iPhone16Pro = "iPhone 16 Pro"
        case iPhone16ProMax = "iPhone 16 Pro Max"

        // Apple Watch
        case AppleWatch1 = "Apple Watch 1gen"
        case AppleWatchS1 = "Apple Watch Series 1"
        case AppleWatchS2 = "Apple Watch Series 2"
        case AppleWatchS3 = "Apple Watch Series 3"
        case AppleWatchS4 = "Apple Watch Series 4"
        case AppleWatchS5 = "Apple Watch Series 5"
        case AppleWatchSE = "Apple Watch Special Edition"
        case AppleWatchS6 = "Apple Watch Series 6"
        case AppleWatchS7 = "Apple Watch Series 7"

        // Apple TV
        case AppleTV1 = "Apple TV 1gen"
        case AppleTV2 = "Apple TV 2gen"
        case AppleTV3 = "Apple TV 3gen"
        case AppleTV4 = "Apple TV 4gen"
        case AppleTV_4K = "Apple TV 4K"
        case AppleTV2_4K = "Apple TV 4K 2gen"
        case AppleTV3_4K = "Apple TV 4K 3gen"

        case unrecognized = "?unrecognized?"
    }

    // swiftlint:enable identifier_name

    // MARK: Static Computed Properties

    static var model: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)
            }
        }

        let modelMap: [String: Model] = [
            // Simulator
            "i386": .simulator,
            "x86_64": .simulator,
            "arm64": .simulator,

            // iPod
            "iPod1,1": .iPod1,
            "iPod2,1": .iPod2,
            "iPod3,1": .iPod3,
            "iPod4,1": .iPod4,
            "iPod5,1": .iPod5,
            "iPod7,1": .iPod6,
            "iPod9,1": .iPod7,

            // iPad
            "iPad2,1": .iPad2,
            "iPad2,2": .iPad2,
            "iPad2,3": .iPad2,
            "iPad2,4": .iPad2,
            "iPad3,1": .iPad3,
            "iPad3,2": .iPad3,
            "iPad3,3": .iPad3,
            "iPad3,4": .iPad4,
            "iPad3,5": .iPad4,
            "iPad3,6": .iPad4,
            "iPad6,11": .iPad5, // iPad 2017
            "iPad6,12": .iPad5,
            "iPad7,5": .iPad6, // iPad 2018
            "iPad7,6": .iPad6,
            "iPad7,11": .iPad7, // iPad 2019
            "iPad7,12": .iPad7,
            "iPad11,6": .iPad8, // iPad 2020
            "iPad11,7": .iPad8,
            "iPad12,1": .iPad9, // iPad 2021
            "iPad12,2": .iPad9,
            "iPad13,18": .iPad10,
            "iPad13,19": .iPad10,

            // iPad Mini
            "iPad2,5": .iPadMini,
            "iPad2,6": .iPadMini,
            "iPad2,7": .iPadMini,
            "iPad4,4": .iPadMini2,
            "iPad4,5": .iPadMini2,
            "iPad4,6": .iPadMini2,
            "iPad4,7": .iPadMini3,
            "iPad4,8": .iPadMini3,
            "iPad4,9": .iPadMini3,
            "iPad5,1": .iPadMini4,
            "iPad5,2": .iPadMini4,
            "iPad11,1": .iPadMini5,
            "iPad11,2": .iPadMini5,
            "iPad14,1": .iPadMini6,
            "iPad14,2": .iPadMini6,

            // iPad Pro
            "iPad6,3": .iPadPro9_7,
            "iPad6,4": .iPadPro9_7,
            "iPad7,3": .iPadPro10_5,
            "iPad7,4": .iPadPro10_5,
            "iPad6,7": .iPadPro12_9,
            "iPad6,8": .iPadPro12_9,
            "iPad7,1": .iPadPro2_12_9,
            "iPad7,2": .iPadPro2_12_9,
            "iPad8,1": .iPadPro11,
            "iPad8,2": .iPadPro11,
            "iPad8,3": .iPadPro11,
            "iPad8,4": .iPadPro11,
            "iPad8,9": .iPadPro2_11,
            "iPad8,10": .iPadPro2_11,
            "iPad13,4": .iPadPro3_11,
            "iPad13,5": .iPadPro3_11,
            "iPad13,6": .iPadPro3_11,
            "iPad13,7": .iPadPro3_11,
            "iPad8,5": .iPadPro3_12_9,
            "iPad8,6": .iPadPro3_12_9,
            "iPad8,7": .iPadPro3_12_9,
            "iPad8,8": .iPadPro3_12_9,
            "iPad8,11": .iPadPro4_12_9,
            "iPad8,12": .iPadPro4_12_9,
            "iPad13,8": .iPadPro5_12_9,
            "iPad13,9": .iPadPro5_12_9,
            "iPad13,10": .iPadPro5_12_9,
            "iPad13,11": .iPadPro5_12_9,

            // iPad Air
            "iPad4,1": .iPadAir,
            "iPad4,2": .iPadAir,
            "iPad4,3": .iPadAir,
            "iPad5,3": .iPadAir2,
            "iPad5,4": .iPadAir2,
            "iPad11,3": .iPadAir3,
            "iPad11,4": .iPadAir3,
            "iPad13,1": .iPadAir4,
            "iPad13,2": .iPadAir4,
            "iPad13,16": .iPadAir5,
            "iPad13,17": .iPadAir5,

            // iPhone
            "iPhone3,1": .iPhone4,
            "iPhone3,2": .iPhone4,
            "iPhone3,3": .iPhone4,
            "iPhone4,1": .iPhone4S,
            "iPhone5,1": .iPhone5,
            "iPhone5,2": .iPhone5,
            "iPhone5,3": .iPhone5C,
            "iPhone5,4": .iPhone5C,
            "iPhone6,1": .iPhone5S,
            "iPhone6,2": .iPhone5S,
            "iPhone7,1": .iPhone6Plus,
            "iPhone7,2": .iPhone6,
            "iPhone8,1": .iPhone6S,
            "iPhone8,2": .iPhone6SPlus,
            "iPhone8,4": .iPhoneSE,
            "iPhone9,1": .iPhone7,
            "iPhone9,3": .iPhone7,
            "iPhone9,2": .iPhone7Plus,
            "iPhone9,4": .iPhone7Plus,
            "iPhone10,1": .iPhone8,
            "iPhone10,4": .iPhone8,
            "iPhone10,2": .iPhone8Plus,
            "iPhone10,5": .iPhone8Plus,
            "iPhone10,3": .iPhoneX,
            "iPhone10,6": .iPhoneX,
            "iPhone11,2": .iPhoneXS,
            "iPhone11,4": .iPhoneXSMax,
            "iPhone11,6": .iPhoneXSMax,
            "iPhone11,8": .iPhoneXR,
            "iPhone12,1": .iPhone11,
            "iPhone12,3": .iPhone11Pro,
            "iPhone12,5": .iPhone11ProMax,
            "iPhone12,8": .iPhoneSE2,
            "iPhone13,1": .iPhone12Mini,
            "iPhone13,2": .iPhone12,
            "iPhone13,3": .iPhone12Pro,
            "iPhone13,4": .iPhone12ProMax,
            "iPhone14,4": .iPhone13Mini,
            "iPhone14,5": .iPhone13,
            "iPhone14,2": .iPhone13Pro,
            "iPhone14,3": .iPhone13ProMax,
            "iPhone14,6": .iPhoneSE3,
            "iPhone14,7": .iPhone14,
            "iPhone14,8": .iPhone14Plus,
            "iPhone15,2": .iPhone14Pro,
            "iPhone15,3": .iPhone14ProMax,
            "iPhone15,4": .iPhone15,
            "iPhone15,5": .iPhone15Plus,
            "iPhone16,1": .iPhone15Pro,
            "iPhone16,2": .iPhone15ProMax,
            "iPhone17,3": .iPhone16,
            "iPhone17,4": .iPhone16Plus,
            "iPhone17,1": .iPhone16Pro,
            "iPhone17,2": .iPhone16ProMax,

            // Apple Watch
            "Watch1,1": .AppleWatch1,
            "Watch1,2": .AppleWatch1,
            "Watch2,6": .AppleWatchS1,
            "Watch2,7": .AppleWatchS1,
            "Watch2,3": .AppleWatchS2,
            "Watch2,4": .AppleWatchS2,
            "Watch3,1": .AppleWatchS3,
            "Watch3,2": .AppleWatchS3,
            "Watch3,3": .AppleWatchS3,
            "Watch3,4": .AppleWatchS3,
            "Watch4,1": .AppleWatchS4,
            "Watch4,2": .AppleWatchS4,
            "Watch4,3": .AppleWatchS4,
            "Watch4,4": .AppleWatchS4,
            "Watch5,1": .AppleWatchS5,
            "Watch5,2": .AppleWatchS5,
            "Watch5,3": .AppleWatchS5,
            "Watch5,4": .AppleWatchS5,
            "Watch5,9": .AppleWatchSE,
            "Watch5,10": .AppleWatchSE,
            "Watch5,11": .AppleWatchSE,
            "Watch5,12": .AppleWatchSE,
            "Watch6,1": .AppleWatchS6,
            "Watch6,2": .AppleWatchS6,
            "Watch6,3": .AppleWatchS6,
            "Watch6,4": .AppleWatchS6,
            "Watch6,6": .AppleWatchS7,
            "Watch6,7": .AppleWatchS7,
            "Watch6,8": .AppleWatchS7,
            "Watch6,9": .AppleWatchS7,

            // Apple TV
            "AppleTV1,1": .AppleTV1,
            "AppleTV2,1": .AppleTV2,
            "AppleTV3,1": .AppleTV3,
            "AppleTV3,2": .AppleTV3,
            "AppleTV5,3": .AppleTV4,
            "AppleTV6,2": .AppleTV_4K,
            "AppleTV11,1": .AppleTV2_4K,
            "AppleTV14,1": .AppleTV3_4K
        ]

        guard let mcode = modelCode, let model = modelMap[mcode] else { return Model.unrecognized }

        if model == .simulator {
            if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                if let simModel = modelMap[simModelCode] {
                    return simModel
                }
            }
        }
        return model
    }

    // MARK: Static Functions

    // Based on table from: https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
    static func maxiumSupportedTextureSize() -> ImageSize {
        var maxLength: Int = 4096

        guard let device = MTLCreateSystemDefaultDevice() else {
            assertionFailure("Could not create Metal Device")
            return .square(maxLength)
        }

        if device.supportsFamily(.apple1) || device.supportsFamily(.apple2) {
            maxLength = 8192 // A7 and A8 chips
        } else {
            maxLength = 16384 // A9 and later chips
        }
        return .square(maxLength)
    }
}

extension ImageSize {

    func clipToMaximumSupportedTextureSize() -> ImageSize {
        let deviceLimit = DeviceSupport.maxiumSupportedTextureSize()
        var currentSize = self

        // Repeat halving the size until it fits within the device limit
        while currentSize.width > deviceLimit.width || currentSize.height > deviceLimit.height {
            // Halve the size while maintaining the aspect ratio
            currentSize = ImageSize(width: currentSize.width / 2, height: currentSize.height / 2)
        }

        return currentSize
    }
}
