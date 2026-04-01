import SwiftUI

struct BadgePreviewView: View {
    let attendee: Attendee
    let accentColor: Color

    init(attendee: Attendee, accentColor: Color = Color(red: 0.1, green: 0.3, blue: 0.7)) {
        self.attendee = attendee
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Badge Preview")
                .font(.headline)
                .padding(.bottom, 12)

            // Badge card
            VStack(spacing: 0) {
                // Header bar
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 40)
                    .overlay(
                        Text("VISITOR")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                // Badge content
                VStack(spacing: 8) {
                    Text(attendee.name)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(attendee.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(attendee.company)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)

                // Bottom accent
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .frame(width: 288, height: 216)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}
