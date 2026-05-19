import SwiftUI

/// Visual preview of the printed badge. Mirrors the layout drawn by
/// `BadgePrintService.renderBadgeImage` so users can see what will print.
struct BadgePreviewView: View {
    let attendee: Attendee
    var accentColor: Color = DS.Color.primary

    var body: some View {
        VStack(spacing: DS.Spacing.s) {
            Text("Badge Preview")
                .font(.caption.weight(.semibold))
                .foregroundColor(DS.Color.textTertiary)
                .tracking(1.2)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 44)
                    .overlay(
                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "person.fill")
                                .font(.caption.weight(.bold))
                            Text("VISITOR")
                                .font(.system(size: 15, weight: .bold))
                                .tracking(2)
                        }
                        .foregroundColor(.white)
                    )

                VStack(spacing: DS.Spacing.xs) {
                    Text(attendee.name)
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    if !attendee.title.isEmpty {
                        Text(attendee.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }

                    if !attendee.company.isEmpty {
                        Text(attendee.company)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, DS.Spacing.m)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.l)

                Rectangle()
                    .fill(accentColor)
                    .frame(height: 4)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.bottom, DS.Spacing.s)
            }
            .frame(width: 288, height: 216)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.s)
                    .stroke(DS.Color.divider.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
    }
}
