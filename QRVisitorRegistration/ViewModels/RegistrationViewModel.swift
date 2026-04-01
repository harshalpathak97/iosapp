import SwiftUI

@MainActor
class RegistrationViewModel: ObservableObject {
    // MARK: - Published State
    @Published var scannedCode: String?
    @Published var isScanning: Bool = true
    @Published var matchedAttendee: Attendee?
    @Published var registrationLog: [RegistrationRecord] = []

    @Published var currentState: RegistrationState = .scanning
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false

    // MARK: - Services
    let database = AttendeeDatabase()
    let envoyService = EnvoyService()
    let printService = BadgePrintService()

    // MARK: - State Machine
    enum RegistrationState: Equatable {
        case scanning
        case attendeeFound(Attendee)
        case notFound(String)
        case registering
        case completed(Attendee)
        case error(String)

        static func == (lhs: RegistrationState, rhs: RegistrationState) -> Bool {
            switch (lhs, rhs) {
            case (.scanning, .scanning): return true
            case (.attendeeFound(let a), .attendeeFound(let b)): return a.id == b.id
            case (.notFound(let a), .notFound(let b)): return a == b
            case (.registering, .registering): return true
            case (.completed(let a), .completed(let b)): return a.id == b.id
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    init() {
        envoyService.loadSavedConfiguration()
    }

    // MARK: - QR Code Processing

    func processScannedCode(_ code: String) {
        scannedCode = code
        isScanning = false

        let linkedInURL = extractLinkedInURL(from: code)
        statusMessage = "Looking up: \(linkedInURL)"

        if let attendee = database.findAttendee(byLinkedInURL: linkedInURL) {
            matchedAttendee = attendee
            currentState = .attendeeFound(attendee)
            statusMessage = "Found: \(attendee.name)"
        } else {
            matchedAttendee = nil
            currentState = .notFound(linkedInURL)
            statusMessage = "No attendee found for this LinkedIn profile"
        }
    }

    /// Extract the LinkedIn profile URL from a scanned QR code value.
    /// LinkedIn QR codes can contain various URL formats.
    private func extractLinkedInURL(from code: String) -> String {
        // LinkedIn QR codes typically encode the profile URL directly
        // e.g., "https://www.linkedin.com/in/johndoe"
        // Some may use short URLs like "https://www.linkedin.com/in/johndoe?trk=qr"
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove tracking parameters but keep the core URL
        if let urlComponents = URLComponents(string: trimmed) {
            var cleaned = URLComponents()
            cleaned.scheme = urlComponents.scheme
            cleaned.host = urlComponents.host
            cleaned.path = urlComponents.path
            return cleaned.url?.absoluteString ?? trimmed
        }

        return trimmed
    }

    // MARK: - Registration Flow

    func registerAttendee(_ attendee: Attendee) async {
        currentState = .registering
        isLoading = true
        statusMessage = "Registering \(attendee.name)..."

        var envoySuccess = false

        // Try Envoy API sign-in
        if envoyService.isConfigured {
            do {
                let result = try await envoyService.signInVisitor(attendee: attendee)
                envoySuccess = result.success
                statusMessage = result.message
            } catch {
                statusMessage = "Envoy sign-in failed: \(error.localizedDescription). Continuing with badge print."
                envoySuccess = false
            }
        } else {
            // Try opening Envoy app via URL scheme
            let opened = envoyService.openEnvoyApp(for: attendee)
            envoySuccess = opened
            if !opened {
                statusMessage = "Envoy not configured. Proceeding with badge print only."
            }
        }

        let record = RegistrationRecord(
            attendee: attendee,
            envoySignInSuccess: envoySuccess,
            badgePrinted: false
        )
        registrationLog.insert(record, at: 0)

        currentState = .completed(attendee)
        isLoading = false
    }

    // MARK: - Badge Printing

    func printBadge(for attendee: Attendee, from viewController: UIViewController) {
        printService.printBadge(for: attendee, from: viewController) { [weak self] success, message in
            DispatchQueue.main.async {
                self?.statusMessage = message
                // Update the most recent log record
                if let index = self?.registrationLog.firstIndex(where: { $0.attendee.id == attendee.id }) {
                    let old = self?.registrationLog[index]
                    if let old = old {
                        self?.registrationLog[index] = RegistrationRecord(
                            attendee: old.attendee,
                            envoySignInSuccess: old.envoySignInSuccess,
                            badgePrinted: success
                        )
                    }
                }
            }
        }
    }

    // MARK: - Reset

    func resetToScanning() {
        scannedCode = nil
        matchedAttendee = nil
        currentState = .scanning
        statusMessage = ""
        isScanning = true
        isLoading = false
    }
}
