//
//  DiscoverSectionView.swift
//  HudHud
//
//  Created by Alaa . on 14/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DiscoverSectionView: View {
	// we need to know if there's a need for nav link or not
	// content type?
	// title
    var body: some View {
		VStack {
			HStack {
				// title + navigation link
				Text("Favoraties")
					.font(.title3)
					.bold()
				
				Text("view more >")
					.font(.headline)
			}
			// content
		}
    }
}

#Preview {
    DiscoverSectionView()
}
