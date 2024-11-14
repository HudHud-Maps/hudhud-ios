//
//  AmenitiesSectionView.swift
//  HudHud
//
//  Created by Alaa . on 28/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct AmenitiesSectionView: View {

    // MARK: Properties

    var title: String
    var amenities: [String]

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(self.title)
                .hudhudFont(.headline)
                .foregroundStyle(Color.Colors.General._01Black)

            Text(self.amenities.joined(separator: "  ·  "))
                .hudhudFont(.subheadline)
                .foregroundStyle(Color.Colors.General._02Grey)
        }
    }
}

#Preview {
    AmenitiesSectionView(title: "Service Options", amenities: ["Wi-Fi", "Parking", "Restroom", "Outdoor", "Delivery", "Takeaway"])
}
