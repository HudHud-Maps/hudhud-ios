//
//  POIOverviewView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SFSafeSymbols
import SwiftUI

// MARK: - POIOverviewView

struct POIOverviewView: View {

    // MARK: Properties

    let poiData: POISheetStore

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Description
            Text(self.poiData.item.description)
                .hudhudFont(size: 14, fontWeight: .regular)
                .padding(.horizontal)
                .foregroundColor(Color.Colors.General._01Black)

            Divider()
                .background(Color.Colors.General._04GreyForLines)

            VStack(alignment: .leading, spacing: 15) {
                // Location Row
                LocationView(description: self.poiData.item.description)

                // Opening hours detial Row
                if let isOpen = poiData.item.isOpen {
                    OpeningHoursView(isOpen: isOpen, data: self.poiData)
                }

                // Contact detial Row
                if let phone = poiData.item.phone, let website = poiData.item.website?.absoluteString {
                    ContactDetailView(phone: phone, website: website)
                }

                Divider()
                    .background(Color.Colors.General._04GreyForLines)

                // Claim Button
                ClaimBusinessButtonView()
                    .padding(.horizontal)
            }
            .hudhudFont(size: 15, fontWeight: .regular)

            Divider()
                .background(Color.Colors.General._04GreyForLines)

            // Show more button
            ShowMoreButtonView()
                .padding(.horizontal)
        }
    }
}

// MARK: - LocationView

struct LocationView: View {

    // MARK: Properties

    let description: String

    // MARK: Content

    var body: some View {
        HStack {
            Image(systemSymbol: .mappinCircleFill)
                .foregroundColor(.Colors.General._02Grey)
            Text(self.description)
                .foregroundColor(.Colors.General._01Black)
        }
        .padding(.horizontal)
    }
}

// MARK: - OpeningHoursView

struct OpeningHoursView: View {

    // MARK: Properties

    let isOpen: Bool
    let data: POISheetStore

    // MARK: Content

    var body: some View {
        Button(action: {
            withAnimation { self.data.openingHoursExpanded.toggle() }
        }, label: {
            HStack(alignment: .top) {
                Image(systemSymbol: .clockFill)
                    .foregroundColor(.Colors.General._02Grey)
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(self.isOpen ? "Open" : "Closed")
                            .foregroundColor(self.isOpen ? .Colors.General._10GreenMain : .Colors.General._02Grey)
                        Image(systemSymbol: self.data.openingHoursExpanded ? .chevronUp : .chevronDown)
                            .foregroundColor(Color.Colors.General._10GreenMain)
                    }

                    if self.data.openingHoursExpanded {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(POISheetStore.OpeningHours.allCases, id: \.self) { day in
                                HStack {
                                    Text(day.rawValue)
                                        .hudhudFont(.caption)
                                        .foregroundColor(.Colors.General._02Grey)
                                    Spacer()
                                    Text(day.hours)
                                        .hudhudFont(.caption)
                                        .foregroundColor(.Colors.General._02Grey)
                                }
                            }
                        }
                    }
                }
            }
        })
        .padding(.horizontal)
    }
}

// MARK: - ContactDetailView

struct ContactDetailView: View {

    // MARK: Properties

    let phone: String?
    let website: String?

    @Environment(\.openURL) private var openURL

    // MARK: Content

    var body: some View {
        HStack(alignment: .top) {
            Image(systemSymbol: .exclamationmarkCircleFill)
                .foregroundColor(.Colors.General._02Grey)
            VStack(alignment: .leading, spacing: 7) {
                if let phone {
                    Button(action: {
                        if let url = URL(string: "tel://\(phone)") {
                            self.openURL(url)
                        }
                    }, label: {
                        Text(phone)
                            .foregroundColor(.Colors.General._10GreenMain)
                    })
                }
                if let website, let url = URL(string: website) {
                    Link(website, destination: url)
                        .foregroundColor(.Colors.General._10GreenMain)

                    SocialMediaLinksView()
                        .padding(.top, 12)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - SocialMediaLinksView

// Social media

struct SocialMediaLinksView: View {

    // MARK: Properties

    private let icons = ["Facebook", "tiktok", "x", "instgram"]

    // MARK: Content

    var body: some View {
        HStack(spacing: 20) {
            ForEach(self.icons, id: \.self) { icon in
                CircularIconView(iconName: icon)
            }
        }
    }
}

// MARK: - CircularIconView

struct CircularIconView: View {

    // MARK: Properties

    let iconName: String

    // MARK: Content

    //  let iconLink: URL

    var body: some View {
        Button {
            // open url
        } label: {
            Image(self.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundColor(Color.Colors.General._01Black)
                .padding(12)
                .background(Circle()
                    .fill(Color.Colors.General._03LightGrey)
                    .frame(width: 40, height: 40)
                )
        }
    }
}

// MARK: - ClaimBusinessButtonView

struct ClaimBusinessButtonView: View {
    var body: some View {
        Button(action: {
            // Action for claim button
        }, label: {
            HStack {
                Image(systemSymbol: .checkmarkSealFill)
                    .foregroundColor(.Colors.General._02Grey)
                Text("Claim this business")
                    .foregroundColor(.Colors.General._06DarkGreen)
            }
        })
    }
}

// MARK: - ShowMoreButtonView

struct ShowMoreButtonView: View {
    var body: some View {
        Button(action: {
            // Action for show more button
        }, label: {
            Text("Show more")
                .foregroundColor(.Colors.General._06DarkGreen)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.Colors.General._03LightGrey)
                .cornerRadius(100)
        })
    }
}

#Preview {
    POIOverviewView(poiData: POISheetStore(item: .artwork))
}
