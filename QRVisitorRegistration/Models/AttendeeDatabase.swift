import Foundation
import Combine

class AttendeeDatabase: ObservableObject {
    @Published var attendees: [Attendee] = []

    init() {
        loadAttendees()
    }

    func loadAttendees() {
        guard let url = Bundle.main.url(forResource: "attendees", withExtension: "json") else {
            print("AttendeeDatabase: attendees.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Attendee].self, from: data)
            self.attendees = decoded
            print("AttendeeDatabase: Loaded \(decoded.count) attendees")
        } catch {
            print("AttendeeDatabase: Failed to decode attendees.json - \(error)")
        }
    }

    /// Normalize a LinkedIn URL for comparison by stripping protocol, trailing slashes, and query params
    private func normalizeLinkedInURL(_ url: String) -> String {
        var normalized = url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove protocol
        if let range = normalized.range(of: "https://") {
            normalized = String(normalized[range.upperBound...])
        } else if let range = normalized.range(of: "http://") {
            normalized = String(normalized[range.upperBound...])
        }

        // Remove www.
        if normalized.hasPrefix("www.") {
            normalized = String(normalized.dropFirst(4))
        }

        // Remove query parameters
        if let queryIndex = normalized.firstIndex(of: "?") {
            normalized = String(normalized[..<queryIndex])
        }

        // Remove trailing slash
        while normalized.hasSuffix("/") {
            normalized = String(normalized.dropLast())
        }

        return normalized
    }

    /// Look up an attendee by their LinkedIn URL extracted from a QR code
    func findAttendee(byLinkedInURL scannedURL: String) -> Attendee? {
        let normalizedScanned = normalizeLinkedInURL(scannedURL)

        return attendees.first { attendee in
            let normalizedStored = normalizeLinkedInURL(attendee.linkedinURL)
            return normalizedScanned == normalizedStored
        }
    }

    /// Search attendees by name (for manual lookup)
    func searchAttendees(query: String) -> [Attendee] {
        guard !query.isEmpty else { return attendees }
        let lowered = query.lowercased()
        return attendees.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.company.lowercased().contains(lowered) ||
            $0.title.lowercased().contains(lowered)
        }
    }

    /// Reload the database (e.g., if the JSON file is updated)
    func reload() {
        loadAttendees()
    }
}
