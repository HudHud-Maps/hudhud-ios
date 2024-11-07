//
//  AlertView.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - AlertInfo

struct AlertInfo {
    let progress: CGFloat
    let duration: String
    let time: String
    let distance: String
    let alertType: AlertType
    let alertDistance: Int
}

// MARK: - AlertType

enum AlertType {
    case speedCamera
    case carAccident

    // MARK: Computed Properties

    var icon: String {
        switch self {
        case .speedCamera: return "camera.fill"
        case .carAccident: return "car.fill"
        }
    }

    var color: Color {
        switch self {
        case .speedCamera: return .red
        case .carAccident: return .orange
        }
    }
}

// MARK: - AlertView

struct AlertView: View {

    // MARK: Properties

    let info: AlertInfo

    // MARK: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(spacing: 4) {
                Text(self.info.duration)
                Text("•")
                Text(self.info.time)
                Text("•")
                Text(self.info.distance)
            }
            .foregroundColor(Color.gray)
            .font(.system(size: 17))
            .padding(.top, 16)

            GeometryReader { geometry in
                Rectangle()
                    .fill(self.info.alertType.color)
                    .frame(width: geometry.size.width * self.info.progress)
                    .frame(height: 2)
            }
            .frame(height: 2)
            .padding(.top, 16)

            HStack(spacing: 12) {
                Image(systemName: self.info.alertType.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(self.info.alertType.color)
                    .cornerRadius(8)

                Text("\(self.info.alertType == .speedCamera ? "Speed camera" : "Car accident") in \(self.info.alertDistance) m")
                    .font(.system(size: 20, weight: .regular))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.white)
        .cornerRadius(24)
    }
}
