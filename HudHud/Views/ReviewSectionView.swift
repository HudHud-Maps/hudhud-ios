//
//  ReviewSectionView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 10/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - ReviewSectionView

struct ReviewSectionView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            userView(review: self.review)

            RatingsView(review: self.review)

            // Review Text
            Text(self.review.reviewText)
                .hudhudFont(.body)
                .lineLimit(nil)
                .foregroundStyle(Color.Colors.General._01Black)

            bottomBar(isUseful: self.review.isUseful, usefulCount: self.review.usefulCount)
                .padding(.top)

            Divider()
        }
        .padding()
    }
}

// MARK: - userView

struct userView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        HStack {
            Image(systemSymbol: .personCircleFill)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(self.review.username)
                    .hudhudFont(.headline)
                Text("From \(self.review.userType)")
                    .hudhudFont(.subheadline)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
    }
}

// MARK: - RatingsView

struct RatingsView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(1 ... 5, id: \.self) { index in
                    Image(self.review.rating < Int(index) ? .starOff : .starOn)
                        .resizable()
                        .frame(width: 14, height: 14)
                }
            }
            Text(self.review.date)
                .hudhudFont(.footnote)
                .foregroundStyle(Color.Colors.General._02Grey)
        }
    }
}

// MARK: - bottomBar

struct bottomBar: View {

    // MARK: Properties

    let isUseful: Bool
    let usefulCount: Int

    // MARK: Content

    var body: some View {
        HStack(spacing: 5) {
            Button {
                // like the review
            }
            label: {
                Image(systemSymbol: self.isUseful ? .heartFill : .heart)
                    .foregroundStyle(self.isUseful ? Color.Colors.General._06DarkGreen : Color.Colors.General._02Grey)
            }

            Text("Useful(\(self.usefulCount))")
                .hudhudFont(.footnote)
                .foregroundStyle(self.isUseful ? Color.Colors.General._06DarkGreen : Color.Colors.General._02Grey)

            Spacer()

            Button {
                // naivgate to more view
            }
            label: {
                Image(systemSymbol: .ellipsis)
            }
        }
    }
}

#Preview {
    let review = Review(
        username: "Ahmad Kamal",
        userType: "Trip Advisor", userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!,
        rating: 4,
        date: "12 September 2024",
        reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
        images: [URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!, URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!, URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!],
        isUseful: true,
        usefulCount: 15
    )
    ReviewSectionView(review: review)
}
