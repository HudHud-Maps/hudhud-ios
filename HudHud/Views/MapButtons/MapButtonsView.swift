//
//  MapButtonsView.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct MapButtonsView: View {
	@State var mapButtonsData: [MapButtonData]
    var body: some View {
		VStack(spacing: 0) {
			ForEach(mapButtonsData.indices, id: \.self) { index in
				Button(action: mapButtonsData[index].action) {
					Image(systemSymbol:  mapButtonsData[index].sfSymbol)
						.font(.title)
						.padding(.vertical)
						.padding(.horizontal, 10)
						.foregroundColor(.gray)
				}
				if index != mapButtonsData.count - 1 {
					Divider()
				}
				
			}
		}
		.background(Color.white)
		.cornerRadius(15)
		.shadow(color: .black.opacity(0.1), radius: 10, y: 4)
		.animation(.easeIn, value: mapButtonsData.indices)
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
