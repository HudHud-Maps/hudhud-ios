//
//  APIClient.swift
//  BackendService
//
//  Created by Naif Alrashed on 29/10/2024.
//

import Foundation
import OpenAPIRuntime
@preconcurrency import Pulse

// MARK: - APIClient

public enum APIClient {

    // MARK: Static Properties

    public static let shouldLogRequests: Bool = true

    private static let session: URLSessionProxy = .init(configuration: .default)

    // MARK: Static Computed Properties

    /// use this for open api generated clients
    public static var transport: ClientTransport {
        URLSessionProtocolTransport(session: APIClient.session)
    }

    /// use this for normal url session calls
    public static var urlSession: URLSessionProtocol {
        if APIClient.shouldLogRequests {
            session
        } else {
            URLSession.shared
        }
    }

}
