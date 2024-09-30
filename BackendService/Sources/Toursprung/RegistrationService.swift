//
//  RegistrationService.swift
//  BackendService
//
//  Created by Fatima Aljaber on 13/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import OpenAPIURLSession
import OSLog
import SwiftUI

// MARK: - RegistrationService

public struct RegistrationService {

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public mutating func login(loginInput: String, baseURL: String) async throws -> RegistrationResponse {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)
        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)
        let transport = URLSessionTransport(configuration: transportConfiguration)
        let body = Operations.login.Input.Body.json(
            Components.Schemas.LoginRequest(login_identity: loginInput)
        )
        let headers = Operations.login.Input.Headers(
            Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"
        )
        let response = try await Client.makeClient(using: baseURL, transport: transport).login(headers: headers, body: body)

        switch response {
        case let .created(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                guard
                    let id = jsonResponse.data.value1.id,
                    let canRequestOtpResendAt = jsonResponse.data.value1.can_request_otp_resend_at else {
                    throw HudHudClientError.internalServerError("login failed")
                }
                return RegistrationResponse(id: id, canRequestOtpResendAt: canRequestOtpResendAt)
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .badRequest(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

    public func verifyOTP(loginId: String, otp: String, baseURL: String) async throws {
        let header = Operations.verifyOTP.Input.Headers(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US")
        let path = Operations.verifyOTP.Input.Path(id: loginId)
        let verifyOTPRequest = Components.Schemas.VerifyOTPRequest(otp: otp)
        let body = Operations.verifyOTP.Input.Body.json(verifyOTPRequest)

        let response = try await Client.makeClient(using: baseURL).verifyOTP(path: path, headers: header, body: body)

        switch response {
        case .ok:
            return
        case let .badRequest(error):
            let errorMessage = try error.body.json.message
            throw HudHudClientError.badRequest(errorMessage)
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .unauthorized(error):
            let errorMessage = try error.body.json.message
            throw HudHudClientError.badRequest(errorMessage)
        case let .notFound(error):
            let errorMessage = try error.body.json.message
            throw HudHudClientError.notFound(errorMessage)
        case let .gone(error):
            let errorMessage = try error.body.json.message
            throw HudHudClientError.gone(errorMessage)
        }
    }

    public func resendOTP(loginId: String, baseURL: String) async throws -> RegistrationResponse {
        let path = Operations.resendOTP.Input.Path(id: loginId)
        let response = try await Client.makeClient(using: baseURL).resendOTP(path: path)

        switch response {
        case let .ok(created):
            switch created.body {
            case let .json(jsonResponse):
                guard let canRequestOtpResendAt = jsonResponse.data.value1.can_request_otp_resend_at else {
                    throw HudHudClientError.internalServerError("login failed")
                }
                return RegistrationResponse(id: loginId, canRequestOtpResendAt: canRequestOtpResendAt)
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .badRequest(error):
            throw try HudHudClientError.badRequest(error.body.json.message.debugDescription)
        case let .notFound(error):
            let errorMessage = try error.body.json.message
            throw HudHudClientError.notFound(errorMessage)
        case let .gone(error):
            let errorMessage = try error.body.json.message
            throw HudHudClientError.gone(errorMessage)
        }
    }
}

// MARK: - RegistrationResponse

public struct RegistrationResponse {

    public let id: String
    public let canRequestOtpResendAt: Date
}
