//
//  HudHudClient.swift
//  HudHud
//
//  Created by patrick on 29.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import OpenAPIURLSession
import POIService

struct HudHudClient {
    func resolveItem(id: String) async throws -> ResolvedItem {
        let client = Client(serverURL: URL(string: "https://hudhud.sa")!, transport: URLSessionTransport())

        let response = try await client.getPoi(path: .init(id: id))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let resolvedItem = ResolvedItem(id: <#T##String#>, title: <#T##String#>, subtitle: <#T##String#>, category: <#T##String?#>, symbol: <#T##SFSymbol#>, type: <#T##PredictionResult#>, coordinate: <#T##CLLocationCoordinate2D#>, phone: <#T##String?#>, website: <#T##URL?#>)
            }
        case .notFound:
            <#code#>
        case let .undocumented(statusCode: statusCode, _):
            <#code#>
        }
    }
}
