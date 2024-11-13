//
//  ReviewStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 10/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - Review

struct Review: Identifiable {
    let id = UUID()
    let username: String
    let userType: String
    let userImage: URL
    let rating: Int
    let date: String
    let reviewText: String
    let images: [URL]
    let isUseful: Bool
    let usefulCount: Int
}

extension Review {
    static var reviewForPreview = Review(username: "Ahmad Kamal",
                                         userType: "Trip Advisor",
                                         userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                                             defaultImageURL(),
                                         rating: 4,
                                         date: "12 September 2024",
                                         reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
                                         images: [
                                             URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                                                 defaultImageURL()
                                         ],
                                         isUseful: false,
                                         usefulCount: 15)

    static var listOfReviewsForPreview: [Review] = [
        Review(username: "Ahmad Kamal",
               userType: "Trip Advisor",
               userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                   defaultImageURL(),
               rating: 4,
               date: "12 September 2024",
               reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
               images: [
                   URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                       defaultImageURL()
               ],
               isUseful: false,
               usefulCount: 15),
        Review(username: "Noura Ahmed",
               userType: "Trip Advisor",
               userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                   defaultImageURL(),
               rating: 4,
               date: "12 September 2024",
               reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
               images: [
                   URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                       defaultImageURL(),
                   URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                       defaultImageURL(),
                   URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77") ??
                       defaultImageURL()
               ],
               isUseful: false,
               usefulCount: 15)
    ]

    private static func defaultImageURL() -> URL {
        guard let url = URL(string: "https://example.com/default.jpg") else {
            preconditionFailure("Invalid default image URL")
        }
        return url
    }
}
