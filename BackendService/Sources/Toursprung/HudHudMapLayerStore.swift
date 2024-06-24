//
//  HudHudMapLayerStore.swift
//  
//
//  Created by Alaa . on 12/06/2024.
//

import CoreLocation
import Foundation
import OpenAPIURLSession


public class HudHudMapLayerStore: ObservableObject {
    
    @Published public var hudhudMapLayers: [HudHudMapLayer]?
    @Published public var lastError: Error?
    
    public func getMaplayers() async throws -> [HudHudMapLayer] {
        let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.waitsForConnectivity = true
            urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)

        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)

        let transport = URLSessionTransport(configuration: transportConfiguration)
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: transport)

        let response = try await client.listMapStyles()

        switch response {
            
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let mapLayer: [HudHudMapLayer] = jsonResponse.data.compactMap { mapStyle in
                    return HudHudMapLayer(name: mapStyle.name, style_url: mapStyle.style_url, thumbnail_url: mapStyle.thumbnail_url)
                }
                return mapLayer
            }
        case .undocumented(statusCode: let statusCode,  let payload):
            let bodyString: String? = if let body = payload.body {
                            try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                            nil
                        }
                        self.lastError = OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
                        throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }
    
    public init(){

        }
}


public struct HudHudMapLayer: Hashable {
    public let name: String
    public let style_url: String
    public let thumbnail_url: String
}
