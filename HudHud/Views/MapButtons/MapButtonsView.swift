//
//  MapButtonsView.swift
//  HudHud
//
//  Created by Alaa . on 03/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import OSLog
import SwiftUI

struct MapButtonsView: View {
    let mapButtonsData: [MapButtonData]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(self.mapButtonsData.indices, id: \.self) { index in
                Button(action: self.mapButtonsData[index].action) {
                    self.iconView(for: self.mapButtonsData[index].sfSymbol)
                        .padding(10)
                        .foregroundColor(.gray)
                }
                if index != self.mapButtonsData.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .fixedSize()
    }

    // MARK: - Private

    @ViewBuilder
    private func iconView(for style: MapButtonData.IconStyle) -> some View {
        switch style {
        case let .icon(symbol):
            Image(systemSymbol: symbol).font(.title2)
        case let .text(text):
            Text(text)
                .hudhudFont(textStyle: .title2)
                .fontWidth(.compressed)
                .padding(.vertical, -0.8)
        }
    }
}

#Preview {
    MapButtonsView(mapButtonsData: [
        MapButtonData(sfSymbol: .icon(.map)) {
            print("Map button tapped")
        },
        MapButtonData(sfSymbol: .icon(.pano)) {
            print("Provider button tapped")
        },
        MapButtonData(sfSymbol: MapButtonData.buttonIcon(for: .live(provider: .toursprung))) {
            print("Provider button tapped")
        },
        MapButtonData(sfSymbol: .icon(.cube)) {
            print("StreetView button tapped")
        }
    ])
}
