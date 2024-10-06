//
//  POISheetButtonStyle.swift
//  HudHud
//
//  Created by Alaa . on 02/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import SwiftUI

struct POISheetButtonStyle: ButtonStyle {

    // MARK: Properties

    let title: String
    let icon: UIImage
    var backgroundColor: Color? = .Colors.General._20ActionButtons
    var fontColor: Color? = .Colors.General._01Black
    @ScaledMetric var imageSize = 24
    @ScaledMetric var buttonHeight = 48
    @ScaledMetric var buttonWidth = 66

    // MARK: Content

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Image(uiImage: self.icon)
                .frame(width: self.imageSize, height: self.imageSize)
                .padding(.top, 9)
            Text(self.title)
                .hudhudFont(.subheadline)
                .foregroundStyle(self.fontColor ?? .Colors.General._01Black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.vertical, 8)
        }
        .padding(5)
        .frame(width: self.buttonWidth, height: self.buttonHeight)
        .padding(9)
        .background(self.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(configuration.isPressed ? 0.1 : 0.06), radius: 7, y: 4)
    }
}

#Preview {
    Button {} label: {}
        .buttonStyle(POISheetButtonStyle(title: "Call", icon: .phoneFill))
}

#Preview(traits: .sizeThatFitsLayout) {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.select(.coffeeAddressRiyadh)
    return ContentView(
        searchStore: searchViewStore,
        mapViewStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    )
}
