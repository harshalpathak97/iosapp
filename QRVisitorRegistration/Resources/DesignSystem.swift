import SwiftUI

/// Centralized design tokens for the app. Use these instead of hard-coding
/// colors, spacing, or font sizes to keep the UI consistent across screens.
enum DS {

    // MARK: - Colors

    enum Color {
        static let primary = SwiftUI.Color(red: 0.30, green: 0.45, blue: 0.95)
        static let primaryDark = SwiftUI.Color(red: 0.20, green: 0.30, blue: 0.75)
        static let accent = SwiftUI.Color(red: 1.00, green: 0.55, blue: 0.30)
        static let success = SwiftUI.Color(red: 0.20, green: 0.75, blue: 0.45)
        static let warning = SwiftUI.Color(red: 1.00, green: 0.65, blue: 0.20)
        static let danger = SwiftUI.Color(red: 0.95, green: 0.30, blue: 0.35)

        static let background = SwiftUI.Color(.systemBackground)
        static let surface = SwiftUI.Color(.secondarySystemBackground)
        static let surfaceElevated = SwiftUI.Color(.tertiarySystemBackground)

        static let textPrimary = SwiftUI.Color(.label)
        static let textSecondary = SwiftUI.Color(.secondaryLabel)
        static let textTertiary = SwiftUI.Color(.tertiaryLabel)

        static let divider = SwiftUI.Color(.separator)
    }

    // MARK: - Gradients

    enum Gradient {
        static let primary = LinearGradient(
            colors: [Color.primary, Color.primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accent = LinearGradient(
            colors: [Color.accent, Color.accent.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let success = LinearGradient(
            colors: [Color.success, Color.success.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let surface = LinearGradient(
            colors: [Color.surface, Color.surfaceElevated],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Spacing (4pt base scale)

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radii

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: - Animations

    enum Animation {
        static let snappy: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.8)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.65)
    }

    // MARK: - UserDefaults Keys

    enum Keys {
        static let envoyAPIKey = "envoy_api_key"
        static let envoyLocationID = "envoy_location_id"
        static let printerURL = "printer_url"
        static let scraperBackendURL = "scraper_backend_url"
        static let scraperSharedSecret = "scraper_shared_secret"
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    var padding: CGFloat = DS.Spacing.l

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .stroke(DS.Color.divider.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func card(padding: CGFloat = DS.Spacing.l) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Button Styles

struct PrimaryActionButtonStyle: ButtonStyle {
    var tint: Color = DS.Color.primary
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                    .fill(tint)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 6)
            .animation(DS.Animation.snappy, value: configuration.isPressed)
            .disabled(isLoading)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    var tint: Color = DS.Color.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(tint)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DS.Animation.snappy, value: configuration.isPressed)
    }
}

// MARK: - Reusable Components

struct StatusPill: View {
    enum Kind {
        case success, warning, danger, info, neutral

        var color: Color {
            switch self {
            case .success: return DS.Color.success
            case .warning: return DS.Color.warning
            case .danger: return DS.Color.danger
            case .info: return DS.Color.primary
            case .neutral: return DS.Color.textSecondary
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.octagon.fill"
            case .info: return "info.circle.fill"
            case .neutral: return "circle.fill"
            }
        }
    }

    let kind: Kind
    let text: String

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: kind.icon)
                .symbolRenderingMode(.hierarchical)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .foregroundColor(kind.color)
        .padding(.horizontal, DS.Spacing.s)
        .padding(.vertical, DS.Spacing.xs)
        .background(
            Capsule()
                .fill(kind.color.opacity(0.12))
        )
    }
}

/// Initials avatar with a gradient background, used wherever we need to
/// represent an attendee visually without a profile photo.
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 56

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private var gradient: LinearGradient {
        // Deterministic gradient based on name hash so the same person always
        // gets the same color across the app.
        let hash = abs(name.hashValue)
        let palette: [(Color, Color)] = [
            (DS.Color.primary, DS.Color.primaryDark),
            (DS.Color.accent, DS.Color.accent.opacity(0.7)),
            (DS.Color.success, DS.Color.success.opacity(0.6)),
            (Color(red: 0.7, green: 0.4, blue: 0.9), Color(red: 0.5, green: 0.3, blue: 0.8)),
            (Color(red: 0.95, green: 0.5, blue: 0.6), Color(red: 0.85, green: 0.3, blue: 0.5)),
        ]
        let pair = palette[hash % palette.count]
        return LinearGradient(
            colors: [pair.0, pair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(gradient))
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

/// Empty/idle state view used by scanner, log, search results.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var tint: Color = DS.Color.textTertiary

    var body: some View {
        VStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 72, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(tint)
            Text(title)
                .font(.title2.bold())
                .foregroundColor(DS.Color.textPrimary)
            Text(subtitle)
                .font(.body)
                .foregroundColor(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
