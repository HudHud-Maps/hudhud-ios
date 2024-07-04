//
//  POISheetButtonStyle.swift
//  HudHud
//
//  Created by Alaa . on 02/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct POISheetButtonStyle: ButtonStyle {
    let title: String
    let icon: UIImage
    var backgroundColor: Color? = .white
    var fontColor: Color? = .primary
    @ScaledMetric var imageSize = 24
    @ScaledMetric var buttonHeight = 40
    @ScaledMetric var buttonWidth = 55

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 2) {
            Image(uiImage: self.icon)
                .frame(width: self.imageSize, height: self.imageSize)
            Text(self.title)
                .foregroundStyle(self.fontColor ?? .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: self.buttonWidth, height: self.buttonHeight)
        .padding()
        .background(self.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.07), radius: 10, y: 4)
    }
}

#Preview {
    Button {} label: {}
        .buttonStyle(POISheetButtonStyle(title: "Call", icon: .phoneFill))
}
