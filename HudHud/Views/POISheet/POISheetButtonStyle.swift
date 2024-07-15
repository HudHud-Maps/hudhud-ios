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
    let title: String
    let icon: UIImage
    var backgroundColor: Color? = .white
    var fontColor: Color? = .primary
    @ScaledMetric var imageSize = 24
    @ScaledMetric var buttonHeight = 48
    @ScaledMetric var buttonWidth = 66

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Image(uiImage: self.icon)
                .frame(width: self.imageSize, height: self.imageSize)
                .padding(.top, 9)
            Text(self.title)
                .foregroundStyle(self.fontColor ?? .primary)
                .font(.subheadline.bold())
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

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.selectedItem = ResolvedItem(id: UUID().uuidString, title: "Nozomi", subtitle: "7448 King Fahad Rd, Al Olaya, 4255, Riyadh 12331", category: "Restaurant", type: .toursprung, coordinate: CLLocationCoordinate2D(latitude: 24.732211928084162, longitude: 46.87863163915118), color: .systemRed, rating: 4.4, ratingsCount: 230, isOpen: true)
    return ContentView(searchStore: searchViewStore)
}
