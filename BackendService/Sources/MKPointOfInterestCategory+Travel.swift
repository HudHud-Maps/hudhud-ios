//
//  MKPointOfInterestCategory+Travel.swift
//  BackendService
//
//  Created by Patrick Kladek on 14.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapKit
import SFSafeSymbols

extension MKPointOfInterestCategory {

    static let travelPointsOfInterest: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .restaurant, .winery, .hotel]
    static let defaultPointOfInterestSymbolName = "mappin.and.ellipse"

    var symbolName: String {
        switch self {
        case .airport:
            return "airplane"
        case .atm, .bank:
            return "banknote"
        case .bakery, .brewery, .cafe, .foodMarket, .restaurant, .winery:
            return "fork.knife"
        case .campground, .hotel:
            return "bed.double"
        case .carRental, .evCharger, .gasStation, .parking:
            return "car"
        case .laundry, .store:
            return "tshirt"
        case .library, .museum, .school, .theater, .university:
            return "building.columns"
        case .nationalPark, .park:
            return "leaf"
        case .postOffice:
            return "envelope"
        case .publicTransport:
            return "bus"
        default:
            return MKPointOfInterestCategory.defaultPointOfInterestSymbolName
        }
    }

    var symbol: SFSymbol {
        switch self {
        case .airport:
            return .airplane
        case .atm, .bank:
            return .banknote
        case .bakery, .brewery, .cafe, .foodMarket, .restaurant, .winery:
            return .forkKnife
        case .campground, .hotel:
            return .bedDouble
        case .carRental, .evCharger, .gasStation, .parking:
            return .car
        case .laundry, .store:
            return .tshirt
        case .library, .museum, .school, .theater, .university:
            return .buildingColumns
        case .nationalPark, .park:
            return .leaf
        case .postOffice:
            return .envelope
        case .publicTransport:
            return .bus
        default:
            return .mappinAndEllipse
        }
    }
}
