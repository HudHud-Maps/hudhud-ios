//
//  CategoryItemView.swift
//  HudHud
//
//  Created by Naif Alrashed on 29/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

// MARK: - CategoryItemView

struct CategoryItemView: View {

    let item: ResolvedItem
    let directions: () -> Void
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: .zero) {
            POIMediaView(mediaURLs: self.item.mediaURLs)
                .padding(.bottom, 20)
            VStack {
                Text(self.item.title)
                    .hudhudFont(.headline)
                    .foregroundStyle(Color.Colors.General._01Black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let rating = item.rating, let ratingsCount = item.ratingsCount {
                    RatingView(ratingModel: Rating(
                        rating: rating,
                        ratingsCount: ratingsCount
                    ))
                }
                HStack {
                    Text(self.item.category ?? "")
                    if let distance = item.distance {
                        Text("•")
                        Text("\(LengthFormatter.distance.string(fromMeters: distance))")
                    }
                    Spacer()
                }
                .hudhudFont(.caption)
                .foregroundStyle(Color.Colors.General._02Grey)
                if self.item.isOpen ?? false {
                    Text("Open")
                        .hudhudFont(.caption)
                        .foregroundStyle(Color.Colors.General._07BlueMain)
                }
            }
            .padding(.horizontal)
            ScrollView(.horizontal) {
                HStack {
                    CategoryIconButton(
                        icon: "arrowright_circle_icon_fill",
                        title: "Directions",
                        foregroundColor: .white,
                        backgroundColor: Color.Colors.General._07BlueMain,
                        onClick: self.directions
                    )

                    if let phone = item.phone, let url = URL(string: "tel://\(phone)") {
                        CategoryIconButton(
                            icon: "phone_icon",
                            title: "Call",
                            foregroundColor: Color.Colors.General._01Black,
                            backgroundColor: Color.Colors.General._20ActionButtons
                        ) {
                            self.openURL(url)
                        }
                    }

                    if let website = item.website {
                        CategoryIconButton(
                            icon: "website_icon_fill",
                            title: "Website",
                            foregroundColor: Color.Colors.General._01Black,
                            backgroundColor: Color.Colors.General._20ActionButtons
                        ) {
                            self.openURL(website)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top)
    }
}

// MARK: - Rating

struct Rating: Hashable {
    let rating: Double
    let ratingsCount: Int
}

// MARK: - RatingView

struct RatingView: View {

    let ratingModel: Rating

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(self.ratingModel.rating < 1 ? .starOff : .starOn)
                Image(self.ratingModel.rating < 2 ? .starOff : .starOn)
                Image(self.ratingModel.rating < 3 ? .starOff : .starOn)
                Image(self.ratingModel.rating < 4 ? .starOff : .starOn)
                Image(self.ratingModel.rating < 5 ? .starOff : .starOn)
            }
            Text("\(self.ratingModel.rating, specifier: "%.1f")")
                .hudhudFont(.headline)
                .foregroundStyle(Color.Colors.General._01Black)
            Text("(\(self.ratingModel.ratingsCount))")
                .hudhudFont(.headline)
                .foregroundStyle(Color.Colors.General._02Grey)
            Spacer()
        }
    }
}

// MARK: - CategoryIconButton

private struct CategoryIconButton: View {

    let icon: String
    let title: LocalizedStringKey
    let foregroundColor: Color
    let backgroundColor: Color
    let onClick: () -> Void

    var body: some View {
        Button(action: self.onClick) {
            Label(self.title, image: self.icon)
                .foregroundStyle(self.foregroundColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        }
        .background(self.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 5, y: 4)
    }
}

private extension LengthFormatter {
    static let distance: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        return formatter
    }()
}

#Preview {
    CategoryItemView(item: .ketchup) {}
}
