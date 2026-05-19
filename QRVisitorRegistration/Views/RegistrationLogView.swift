import SwiftUI

struct RegistrationLogView: View {
    let records: [RegistrationRecord]

    var body: some View {
        Group {
            if records.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.clipboard",
                    title: "No Registrations Yet",
                    subtitle: "Scan a LinkedIn QR code from the Scanner tab to register your first visitor."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Spacing.s) {
                        summaryBar
                            .padding(.horizontal, DS.Spacing.l)
                            .padding(.top, DS.Spacing.m)

                        ForEach(records) { record in
                            logRow(record)
                                .padding(.horizontal, DS.Spacing.l)
                        }
                    }
                    .padding(.bottom, DS.Spacing.l)
                }
                .background(DS.Color.background)
            }
        }
    }

    private var summaryBar: some View {
        HStack(spacing: DS.Spacing.s) {
            summaryStat(
                count: records.count,
                label: "Total",
                tint: DS.Color.primary
            )
            summaryStat(
                count: records.filter { $0.envoySignInSuccess }.count,
                label: "Signed In",
                tint: DS.Color.success
            )
            summaryStat(
                count: records.filter { $0.badgePrinted }.count,
                label: "Printed",
                tint: DS.Color.accent
            )
        }
    }

    private func summaryStat(count: Int, label: String, tint: Color) -> some View {
        VStack(spacing: DS.Spacing.xxs) {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(tint)
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        )
    }

    private func logRow(_ record: RegistrationRecord) -> some View {
        HStack(spacing: DS.Spacing.m) {
            InitialsAvatar(name: record.attendee.name, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.attendee.name)
                    .font(.headline)
                    .foregroundColor(DS.Color.textPrimary)
                Text("\(record.attendee.title) - \(record.attendee.company)")
                    .font(.subheadline)
                    .foregroundColor(DS.Color.textSecondary)
                    .lineLimit(1)
                Text(record.registeredAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(DS.Color.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DS.Spacing.xxs) {
                statusChip(success: record.envoySignInSuccess, label: "Envoy")
                statusChip(success: record.badgePrinted, label: "Badge")
            }
        }
        .card(padding: DS.Spacing.m)
    }

    private func statusChip(success: Bool, label: String) -> some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: success ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(success ? DS.Color.success : DS.Color.textTertiary)
                .font(.caption)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(success ? DS.Color.success : DS.Color.textTertiary)
        }
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(success ? DS.Color.success.opacity(0.12) : DS.Color.surface)
        )
    }
}
