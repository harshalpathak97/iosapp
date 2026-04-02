import Foundation
import UIKit

/// Integration service for the Envoy Visitor Registration system.
///
/// Envoy provides a REST API for managing visitor sign-ins. This service handles
/// creating invite entries so visitors appear on the Envoy kiosk's "Expected Visitors" list.
/// The kiosk then handles the actual sign-in and badge printing.
///
/// Setup:
/// 1. Obtain an API key from your Envoy dashboard (Settings > Integrations > API)
/// 2. Configure your location ID from the Envoy dashboard
/// 3. Set the values in the app's Settings screen
class EnvoyService: ObservableObject {
    @Published var isConfigured: Bool = false
    @Published var lastError: String?

    private var apiKey: String = ""
    private var locationID: String = ""
    private var baseURL: String = "https://app.envoy.com/api/v3"

    // MARK: - Configuration

    func configure(apiKey: String, locationID: String) {
        self.apiKey = apiKey
        self.locationID = locationID
        self.isConfigured = !apiKey.isEmpty && !locationID.isEmpty

        // Persist configuration
        UserDefaults.standard.set(apiKey, forKey: "envoy_api_key")
        UserDefaults.standard.set(locationID, forKey: "envoy_location_id")
    }

    func loadSavedConfiguration() {
        let savedKey = UserDefaults.standard.string(forKey: "envoy_api_key") ?? ""
        let savedLocation = UserDefaults.standard.string(forKey: "envoy_location_id") ?? ""
        configure(apiKey: savedKey, locationID: savedLocation)
    }

    // MARK: - Create Invite (Pre-Register Visitor)

    /// Create an invite through the Envoy API so the visitor appears on the kiosk.
    /// The Envoy kiosk app will then show the visitor in its "Expected Visitors" list.
    /// The visitor taps their name on the kiosk to complete sign-in and print a badge.
    func createInvite(for attendee: Attendee) async throws -> EnvoySignInResult {
        guard isConfigured else {
            throw EnvoyError.notConfigured
        }

        let url = URL(string: "\(baseURL)/invites")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")

        // Envoy Invites API uses JSON:API format
        // See: https://developers.envoy.com/hub/reference/createinvite
        let payload: [String: Any] = [
            "data": [
                "type": "invites",
                "attributes": [
                    "full-name": attendee.name,
                    "email": attendee.email ?? "",
                    "expected-arrival-at": ISO8601DateFormatter().string(from: Date()),
                    "private-notes": "\(attendee.title) at \(attendee.company) - Registered via QR Scanner"
                ],
                "relationships": [
                    "location": [
                        "data": [
                            "type": "locations",
                            "id": locationID
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EnvoyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return EnvoySignInResult(
                success: true,
                message: "\(attendee.name) added to Envoy kiosk. They can tap their name to sign in."
            )
        case 401:
            throw EnvoyError.unauthorized
        case 422:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown validation error"
            throw EnvoyError.validationError(errorBody)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EnvoyError.apiError(httpResponse.statusCode, errorBody)
        }
    }
}

struct EnvoySignInResult {
    let success: Bool
    let message: String
}

enum EnvoyError: LocalizedError {
    case notConfigured
    case unauthorized
    case invalidResponse
    case validationError(String)
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Envoy API is not configured. Please add your API key and location ID in Settings."
        case .unauthorized:
            return "Invalid Envoy API key. Please check your credentials in Settings."
        case .invalidResponse:
            return "Received an invalid response from Envoy."
        case .validationError(let detail):
            return "Envoy validation error: \(detail)"
        case .apiError(let code, let detail):
            return "Envoy API error (\(code)): \(detail)"
        }
    }
}
