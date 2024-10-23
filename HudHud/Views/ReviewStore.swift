//
//  ReviewStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 10/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

struct Review: Identifiable {
    let id = UUID()
    let username: String
    let userType: String
    let userImage: URL
    let rating: Int
    let date: String
    let reviewText: String
    let images: [URL]
    let isUseful: Bool
    let usefulCount: Int
}
