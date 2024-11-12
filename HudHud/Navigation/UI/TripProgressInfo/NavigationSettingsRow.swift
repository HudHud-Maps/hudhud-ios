//
//  NavigationSettingsRow.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - NavigationSettingsRow

struct NavigationSettingsRow: View {
    var body: some View {
        NavigationLink(destination: NavigationSettingsView()) {
            HStack {
                Image(.navigationSettingsGear)
//                    .foregroundColor(.gray)

                Text("Navigation Settings")
                    .hudhudFont(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 40 / 255, green: 40 / 255, blue: 40 / 255))

                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
    }
}
