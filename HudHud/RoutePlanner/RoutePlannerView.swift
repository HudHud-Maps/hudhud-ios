//
//  RoutePlannerView.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - RoutePlannerView

struct RoutePlannerView: View {

    // MARK: Properties

    @State var routePlannerStore: RoutePlannerStore

    // MARK: Content

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

// MARK: - RoutePlannerRow

struct RoutePlannerRow: View {
    var body: some View {
        HStack {
            Text("Hello, World!")
        }
    }
}

#Preview {
    RoutePlannerView(routePlannerStore: .storeSetUpForPreviewing)
}
