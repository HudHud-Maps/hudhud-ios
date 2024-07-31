//
//  FavoriteCategoriesButton.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

struct FavoriteCategoriesButton: ButtonStyle {
    let sfSymbol: SFSymbol?
    let tintColor: Color?
    @ScaledMetric var imageSize = 24

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Image(systemSymbol: self.sfSymbol ?? .houseFill)
                .resizable()
                .scaledToFit()
                .frame(width: self.imageSize, height: self.imageSize)
                .foregroundColor(self.tintColor)
                .padding(17)
                .background {
                    Circle()
                        .foregroundColor(Color.Colors.General._20ActionButtons)
                        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 5, y: 4)
                }
            configuration.label
                .tint(Color.Colors.General._01Black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}
