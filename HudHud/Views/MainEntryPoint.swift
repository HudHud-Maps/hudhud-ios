//
//  MainEntryPoint.swift
//  HudHud
//
//  Created by Patrick Kladek on 22.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - MainEntryPoint

@main
struct MainEntryPoint {

    static func main() {
        guard self.isProduction() else {
            TestApp.main()
            return
        }

        HudHudApp.main()
    }

    private static func isProduction() -> Bool {
        return NSClassFromString("XCTestCase") == nil
    }
}

// MARK: - TestApp

struct TestApp: App {

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup {
            self.content
        }
    }

    // MARK: Content

    var content: some View {
        VStack(spacing: 10) {
            Image(systemSymbol: .exclamationmarkTriangleFill)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 72))
            Text("Unit Testing in progress")
        }
    }
}

#Preview {
    TestApp()
        .content
}
