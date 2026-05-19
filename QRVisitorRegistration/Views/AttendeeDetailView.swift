import SwiftUI

struct AttendeeDetailView: View {
    let attendee: Attendee
    let onRegister: () -> Void
    let onPrintBadge: () -> Void
    let onCancel: () -> Void
    let isLoading: Bool
    let isCompleted: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                header
                profileCard
                metaCard
                actionButtons
            }
            .padding(DS.Spacing.l)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(DS.Color.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "chevron.left")
                    Text("Scan Again")
                }
                .font(.body.weight(.medium))
                .foregroundColor(DS.Color.primary)
            }

            Spacer()

            if isCompleted {
                StatusPill(kind: .success, text: "Registered")
            } else {
                StatusPill(kind: .info, text: "Ready to Register")
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: DS.Spacing.m) {
            InitialsAvatar(name: attendee.name, size: 120)

            VStack(spacing: DS.Spacing.xxs) {
                Text(attendee.name)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(DS.Color.textPrimary)

                if !attendee.title.isEmpty {
                    Text(attendee.title)
                        .font(.title3.weight(.medium))
                        .foregroundColor(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if !attendee.company.isEmpty {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "building.2.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(DS.Color.primary)
                        Text(attendee.company)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(DS.Color.textPrimary)
                    }
                    .padding(.top, DS.Spacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .card(padding: DS.Spacing.xl)
    }

    // MARK: - Meta Card (contact + LinkedIn)

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            metaRow(
                icon: "link",
                label: "LinkedIn",
                value: attendee.linkedinURL,
                tint: DS.Color.primary,
                monospaced: true
            )

            if let email = attendee.email, !email.isEmpty {
                Divider().opacity(0.4)
                metaRow(
                    icon: "envelope.fill",
                    label: "Email",
                    value: email,
                    tint: DS.Color.accent
                )
            }

            if let phone = attendee.phone, !phone.isEmpty {
                Divider().opacity(0.4)
                metaRow(
                    icon: "phone.fill",
                    label: "Phone",
                    value: phone,
                    tint: DS.Color.success
                )
            }
        }
        .card(padding: DS.Spacing.s)
    }

    private func metaRow(icon: String, label: String, value: String, tint: Color, monospaced: Bool = false) -> some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.Radius.s))

            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(DS.Color.textTertiary)
                Text(value)
                    .font(monospaced ? .caption.monospaced() : .body.weight(.medium))
                    .foregroundColor(DS.Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.s)
        .padding(.vertical, DS.Spacing.s)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isCompleted {
            VStack(spacing: DS.Spacing.s) {
                Button(action: onPrintBadge) {
                    Label("Print Badge", systemImage: "printer.fill")
                }
                .buttonStyle(PrimaryActionButtonStyle(tint: DS.Color.accent))

                Button(action: onCancel) {
                    Label("Scan Next Visitor", systemImage: "qrcode.viewfinder")
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        } else {
            VStack(spacing: DS.Spacing.s) {
                Button(action: onRegister) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Register Visitor", systemImage: "person.badge.plus")
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(isLoading)

                Button(action: onPrintBadge) {
                    Label("Print Badge Only", systemImage: "printer")
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(isLoading)
            }
        }
    }
}
