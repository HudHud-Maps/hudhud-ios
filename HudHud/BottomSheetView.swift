//
//  BottomSheetView.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetView: View {
	let names = ["Holly", "Josh", "Rhonda", "Ted"]
	@State private var searchText = ""

	var body: some View {
		NavigationStack {
			List {
				ForEach(searchResults, id: \.self) { name in
					NavigationLink {
						Text(name)
					} label: {
						Text(name)
					}
				}
			}
		}
		.searchable(text: $searchText, placement: . navigationBarDrawer(displayMode: .always))
	}

	var searchResults: [String] {
		if searchText.isEmpty {
			return names
		} else {
			return names.filter { $0.contains(searchText) }
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		BottomSheetView()
	}
}
