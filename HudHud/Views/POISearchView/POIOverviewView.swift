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
    @State var viewMore: Bool = false
    @Binding var selectedTab: String

    // MARK: Computed Properties

    private var shouldShowButton: Bool {
        let maxCharacters = 250
        return (self.poiData.item.description).count > maxCharacters
    }

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Here should be a description not the address
            SectionView(sfSymbol: nil, title: nil, desrciption: self.poiData.item.description)
                .lineLimit(self.viewMore ? 30 : 7)
            if self.shouldShowButton {
                Button(self.viewMore ? "Show Less" : "Show More") {
                    self.viewMore.toggle()
                }
            }
            Divider()
                .background(Color.Colors.General._04GreyForLines)

            VStack(alignment: .leading, spacing: 15) {
                // Location Row
                SectionView(sfSymbol: .mappinCircleFill, title: nil, desrciption: self.poiData.item.description)
                Divider()
                    .background(Color.Colors.General._04GreyForLines)
                // Floor
                if let floor = poiData.item.floor, self.selectedTab == "About" {
                    SectionView(sfSymbol: .building2, title: nil, desrciption: floor)

                    Divider()
                        .background(Color.Colors.General._04GreyForLines)
                }
                // National Address
                if let nationalAddress = poiData.item.nationalAddress, self.selectedTab == "About" {
                    SectionView(sfSymbol: .building2, title: "National Address", desrciption: nationalAddress)

                    Divider()
                        .frame(height: 1)
                        .background(Color.Colors.General._04GreyForLines)
                }
                // Price Range
                if let priceRangeValue = self.poiData.item.priceRange,
                   let priceRange = HudHudPOI.PriceRange(rawValue: priceRangeValue), self.selectedTab == "About" {
                    SectionView(sfSymbol: .dollarsignCircleFill, title: nil, desrciption: priceRange.displayValue)

                    Divider()
                        .background(Color.Colors.General._04GreyForLines)
                }

                // Opening hours detail Row
                if let isOpen = poiData.item.isOpen {
                    OpeningHoursView(isOpen: isOpen, data: self.poiData)
                }

                // Contact detail Row
                if let phone = poiData.item.phone, let website = poiData.item.website?.absoluteString {
                    ContactDetailView(phone: phone, website: website)
                    Divider()
                        .background(Color.Colors.General._04GreyForLines)
                }

                // Claim Button
                ClaimBusinessButtonView()
                    .padding(.horizontal)
            }
            .hudhudFont(size: 15, fontWeight: .regular)

            // if tab == overview
            if self.selectedTab != "About" {
                Divider()
                    .background(Color.Colors.General._04GreyForLines)

                // Show more button
                ShowMoreButtonView {
                    self.selectedTab = ""
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.white)
        .cornerRadius(20)
    }
}

// MARK: - SectionView

struct SectionView: View {

    // MARK: Properties

    let sfSymbol: SFSymbol?
    let title: String?
    let desrciption: String

    // MARK: Content

    var body: some View {
        HStack {
            // icon
            if let sfSymbol {
                Image(systemSymbol: sfSymbol)
                    .foregroundColor(.Colors.General._02Grey)
            }
            // Text
            VStack(alignment: .leading) {
                if let title {
                    Text(title)
                        .hudhudFont(size: 14, fontWeight: .regular)
                        .foregroundColor(.Colors.General._02Grey)
                }
                Text(self.desrciption)
                    .hudhudFont(size: 14, fontWeight: .regular)
                    .foregroundColor(.Colors.General._01Black)
            }
            .padding(.leading, 5)
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

    // MARK: Properties

    let action: () -> Void

    // MARK: Content

    var body: some View {
        Button {
            self.action()
        } label: {
            Text("Show more")
                .foregroundColor(.Colors.General._06DarkGreen)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.Colors.General._03LightGrey)
                .cornerRadius(100)
        }
    }
}

#Preview {
    @Previewable @State var overview = "Overview"
    POIOverviewView(poiData: POISheetStore(item: .artwork), selectedTab: $overview)
}

#Preview("About") {
    @Previewable @State var about = "About"
    POIOverviewView(poiData: POISheetStore(item: .ketchup), selectedTab: $about)
}
