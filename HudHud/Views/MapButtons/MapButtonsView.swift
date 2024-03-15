//
//  MapButtonsView.swift
//  HudHud
//
//  Created by Alaa . on 03/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct MapButtonsView: View {
	@State var mapButtonsData: [MapButtonData]

	var body: some View {
		VStack(spacing: 0) {
			ForEach(self.mapButtonsData.indices, id: \.self) { index in
				Button(action: self.mapButtonsData[index].action) {
					Image(systemSymbol: self.mapButtonsData[index].sfSymbol)
						.font(.title2)
						.padding(.vertical, 10)
						.padding(.horizontal, 10)
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
}

#Preview {
	MapButtonsView(mapButtonsData: [
		MapButtonData(sfSymbol: .map) {
			print("Map button tapped")
		},
		MapButtonData(sfSymbol: .location) {
			print("Location button tapped")
		},
		MapButtonData(sfSymbol: .cube) {
			print("Location button tapped")
		}
	])
}
