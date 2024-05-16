//
//  SafariWebView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SafariServices
import SwiftUI

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    // MARK: - Internal

    func makeUIViewController(context _: Context) -> SFSafariViewController {
        return SFSafariViewController(url: self.url)
    }

    func updateUIViewController(_: SFSafariViewController, context _: Context) {
        return
    }
}
