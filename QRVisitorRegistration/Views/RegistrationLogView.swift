import SwiftUI

struct RegistrationLogView: View {
    let records: [RegistrationRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No registrations yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Scan a QR code to register a visitor")
                            .font(.body)
                            .foregroundColor(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(records) { record in
                        HStack(spacing: 16) {
                            // Initials circle
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                Text(initials(for: record.attendee.name))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.attendee.name)
                                    .font(.headline)
                                Text("\(record.attendee.title) - \(record.attendee.company)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(record.registeredAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.tertiary)
                            }

                            Spacer()

                            // Status icons
                            VStack(spacing: 4) {
                                Image(systemName: record.envoySignInSuccess ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundColor(record.envoySignInSuccess ? .green : .gray)
                                Text("Envoy")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 4) {
                                Image(systemName: record.badgePrinted ? "printer.fill" : "printer")
                                    .foregroundColor(record.badgePrinted ? .green : .gray)
                                Text("Badge")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Registration Log (\(records.count))")
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
