import SwiftUI

struct AttendeeDetailView: View {
    let attendee: Attendee
    let onRegister: () -> Void
    let onPrintBadge: () -> Void
    let onCancel: () -> Void
    let isLoading: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Scan Again")
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }

                Spacer()

                Text("Visitor Details")
                    .font(.title2.bold())

                Spacer()

                // Balance spacer
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Scan Again")
                }
                .font(.body)
                .opacity(0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))

            Divider()

            // Main content
            ScrollView {
                VStack(spacing: 32) {
                    // Profile card
                    VStack(spacing: 20) {
                        // Avatar circle with initials
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Text(initials(for: attendee.name))
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)

                        // Name
                        Text(attendee.name)
                            .font(.system(size: 34, weight: .bold))
                            .multilineTextAlignment(.center)

                        // Title & Company
                        VStack(spacing: 6) {
                            Text(attendee.title)
                                .font(.title3)
                                .foregroundColor(.secondary)

                            Text(attendee.company)
                                .font(.title3.weight(.medium))
                                .foregroundColor(.primary)
                        }

                        // LinkedIn link
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text(attendee.linkedinURL)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .padding(32)
                    .frame(maxWidth: 500)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)

                    // Action buttons
                    if isCompleted {
                        VStack(spacing: 16) {
                            Label("Registration Complete", systemImage: "checkmark.circle.fill")
                                .font(.title2.bold())
                                .foregroundColor(.green)

                            Button(action: onPrintBadge) {
                                Label("Print Badge", systemImage: "printer.fill")
                                    .font(.title3.weight(.semibold))
                                    .frame(maxWidth: 360, minHeight: 56)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)

                            Button(action: onCancel) {
                                Text("Scan Next Visitor")
                                    .font(.title3.weight(.medium))
                                    .frame(maxWidth: 360, minHeight: 56)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Button(action: onRegister) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: 360, minHeight: 56)
                                } else {
                                    Label("Register & Sign In", systemImage: "person.badge.plus")
                                        .font(.title3.weight(.semibold))
                                        .frame(maxWidth: 360, minHeight: 56)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(isLoading)

                            Button(action: onPrintBadge) {
                                Label("Print Badge Only", systemImage: "printer.fill")
                                    .font(.title3.weight(.medium))
                                    .frame(maxWidth: 360, minHeight: 56)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isLoading)
                        }
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
