//
//  emptyTest.swift
//  emptyTest
//
//  Created by Patrick Kladek on 22.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Testing

struct emptyTest {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let text = "Hello World"
        #expect(text == "Hello World")
    }
}
